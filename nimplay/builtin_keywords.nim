import macros
import strformat
import tables
import strutils
import sequtils

import ./types, ./utils, ./storage


proc is_dot_variable(node: NimNode): bool =
    if node.kind == nnkDotExpr:
        var correct_types = (node[0].kind, node[1].kind) == (nnkIdent, nnkIdent)
        var correct_length = node.len == 2
        if correct_types and correct_length:
            return true
    return false


proc is_message_sender(node: NimNode): bool =
    if is_dot_variable(node) and node[0].strVal == "msg" and node[1].strVal == "sender":
            return true
    return false


proc has_self(node: NimNode, global_ctx: GlobalContext): bool =
    if is_dot_variable(node) and node[0].strVal == "self":
        if node[1].strVal in global_ctx.global_variables:
            return true
        else:
            raiseParserError(
                fmt"Invalid global variable {node[1].strVal}, has not been defined.", 
                node
            )
    return false


proc has_self_assignment(node: NimNode, global_ctx: GlobalContext): bool =
    if node.kind == nnkAsgn:
        if is_dot_variable(node[0]) and node[0][0].strVal == "self":
            return true
    return false


proc is_keyword(node: NimNode, global_ctx: GlobalContext): (bool, string) =
    if is_message_sender(node):
        return (true, "msg.sender")
    elif has_self_assignment(node, global_ctx):
        return (true, "set_self." & node[0][1].strVal)
    elif has_self(node, global_ctx):
        return (true, "self." & node[1].strVal)
    else:
        return (false, "")


proc find_builtin_keywords(func_body: NimNode, used_keywords: var seq[string], global_ctx: GlobalContext) =
    for child in func_body:
        let (is_kw, kw_key_name) = is_keyword(child, global_ctx)
        if is_kw and not ("set_" & kw_key_name in used_keywords):
                used_keywords.add(kw_key_name)
        find_builtin_keywords(child, used_keywords, global_ctx)


proc generate_defines(keywords: seq[string], global_ctx: GlobalContext): (NimNode, Table[string, string]) =
    # Allocate keywords that do not alter their value 
    # during execution of a function e.g. msg.sender, msg.value etc.  
    var stmts = newStmtList()
    var tmp_vars = initTable[string, string]()
    if "msg.sender" in keywords:
        var tmp_var_name = fmt"msg_sender_tmp_variable_alloc"
        stmts.add(
            nnkStmtList.newTree(
                nnkVarSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode(tmp_var_name),
                        newIdentNode("address"),
                        newEmptyNode()
                    )
                ),
                nnkCall.newTree(
                    newIdentNode("getCaller"),
                    nnkCommand.newTree(
                        newIdentNode("addr"),
                        newIdentNode(tmp_var_name)
                    )
                )
            )
        )
        tmp_vars["msg.sender"] = tmp_var_name

    for kw in keywords:
        if kw.startsWith("set_self"):
            var (new_proc, new_proc_name) = generate_storage_set_func(kw, global_ctx)
            tmp_vars[kw] = new_proc_name
            stmts.add(
                new_proc
            )
        elif kw.startsWith("self"):
            var (new_proc, new_proc_name) = generate_storage_get_func(kw, global_ctx)
            tmp_vars[kw] = new_proc_name
            stmts.add(
                new_proc
            )

    return (stmts, tmp_vars)


proc get_keyword_defines*(proc_def: NimNode, global_ctx: GlobalContext): (NimNode, Table[string, string]) =
    var keywords_used: seq[string]
    find_builtin_keywords(proc_def, keywords_used, global_ctx)
    keywords_used = deduplicate(keywords_used)
    let (global_define_stmts, global_keyword_map) = generate_defines(keywords_used, global_ctx)
    return (global_define_stmts, global_keyword_map)


proc replace_keywords*(ast_node: NimNode, global_keyword_map: Table[string, string], global_ctx: GlobalContext): NimNode  =
    var res_node = copyNimNode(ast_node)
    for child in ast_node:
        var next: NimNode
        let (is_kw, kw_key_name) = is_keyword(child, global_ctx)
        if is_kw and kw_key_name.startsWith("self."):
            next = nnkCall.newTree(
                newIdentNode(global_keyword_map[kw_key_name])
            )
        elif is_kw and kw_key_name.startsWith("set_self."):
            next = nnkCall.newTree(
                newIdentNode(global_keyword_map[kw_key_name]),
                child[1]
            )
        elif is_kw:
            next = newIdentNode(global_keyword_map[kw_key_name])
        else:
            next = child
        res_node.add(replace_keywords(next, global_keyword_map, global_ctx))
    return res_node
