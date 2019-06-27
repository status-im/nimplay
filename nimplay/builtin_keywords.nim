import macros
import strformat
import tables


proc is_message_sender(node: NimNode): bool =
    if node.kind == nnkDotExpr:
        if node.len == 2 and node[0].strVal == "msg" and node[1].strVal == "sender":
            return true
    return false


proc is_keyword(node: NimNode): (bool, string) =
    if is_message_sender(node):
        return (true, "msg.sender")
    else:
        return (false, "")


proc find_builtin_keywords(func_body: NimNode, used_keywords: var seq[string]) =
    for child in func_body:
        let (is_kw, kw_key_name) = is_keyword(child)
        if is_kw:
            used_keywords.add(kw_key_name)
        find_builtin_keywords(child, used_keywords)


proc generate_defines(keywords: seq[string]): (NimNode, Table[string, string]) =
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
    return (stmts, tmp_vars)


proc get_keyword_defines*(proc_def: NimNode): (NimNode, Table[string, string]) =
    var keywords_used: seq[string]
    find_builtin_keywords(proc_def, keywords_used)
    let (global_define_stmts, global_keyword_map) = generate_defines(keywords_used)
    return (global_define_stmts, global_keyword_map)


proc replace_keywords*(ast_node: NimNode, global_keyword_map: Table[string, string]): NimNode  =
    var res_node = copyNimNode(ast_node)
    for child in ast_node:
        var next: NimNode
        let (is_kw, kw_key_name) = is_keyword(child)
        if is_kw:
            next = newIdentNode(global_keyword_map[kw_key_name])
        else:
            next = child
        res_node.add(replace_keywords(next, global_keyword_map))
    return res_node
