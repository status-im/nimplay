import
  macros, strformat, tables,
  strutils, sequtils, algorithm

import
  ./types, ./utils, ./storage,
  ./logging


proc extract_keys(base_node: NimNode, keys: var seq[NimNode]) =
  for x in base_node:
    if x.kind == nnkBracketExpr:
      extract_keys(x, keys)
    else:
      keys.add(x)


proc check_global_exists(global_ctx: GlobalContext, var_name: string, node: NimNode) =
  if not (var_name in global_ctx.global_variables):
    raiseParserError(
      fmt"Invalid global variable {var_name}, has not been defined.",
      node
    )


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


proc is_message_value(node: NimNode): bool =
  if is_dot_variable(node) and node[0].strVal == "msg" and node[1].strVal == "value":
    return true
  return false


proc has_self(node: NimNode, global_ctx: GlobalContext): bool =
  if is_dot_variable(node) and node[0].strVal == "self":
    global_ctx.check_global_exists(node[1].strVal, node)
    if node[1].strVal in global_ctx.global_variables:
      return true
  return false


proc is_log_statement(node: NimNode, global_ctx: GlobalContext): bool =
  if node.kind == nnkCall:
    if is_dot_variable(node[0]) and strVal(node[0][0]) == "log":
      var
        func_name = strVal(node[0][1])
      if func_name in global_ctx.events:
        for func_name in global_ctx.events.keys():
          return true
      else:
        raiseParserError(
          fmt"Invalid log statement {func_name}, event was not defined.",
          node
        )


proc has_self_assignment(node: NimNode): bool =
  if node.kind == nnkAsgn:
    if is_dot_variable(node[0]) and node[0][0].strVal == "self":
      return true
  return false


proc has_self_storage_table_set(node: NimNode, global_ctx: GlobalContext): (bool, NimNode) =
  var n: NimNode
  if node.kind == nnkAsgn and node[0].kind == nnkBracketExpr:
    for x in node:
      n = x
      if is_dot_variable(n[0][0]) and n[0][0][0].strVal == "self":
        var var_name = strVal(n[0][0][1])
        global_ctx.check_global_exists(var_name, n[0][0][1])
        return (true, n)
  return (false, n)


proc has_self_storage_table_get(node: NimNode, global_ctx: GlobalContext): (bool, NimNode) =
  var n: NimNode
  echo treeRepr(node)
  if node.kind == nnkBracketExpr:
    var keys: seq[NimNode]
    extract_keys(node, keys)
    if keys.len > 0 and is_dot_variable(keys[0]) and strVal(keys[0][0]) == "self":
      return (true, keys[0])
  return (false, node)


proc is_keyword(node: NimNode, global_ctx: GlobalContext): (bool, string) =
  # Check for table set.
  var 
    (valid, sub_node) = has_self_storage_table_set(node, global_ctx)
  if valid:
    return (true, "set_table_self." & strVal(sub_node[0][0][1]))

  (valid, sub_node) = has_self_storage_table_get(node, global_ctx)
  if valid:
    return (true, "get_table_self." & strVal(sub_node[1]))

  if is_message_sender(node):
    return (true, "msg.sender")
  elif is_message_value(node):
    return (true, "msg.value")
  elif has_self_assignment(node):
    return (true, "set_self." & strVal(node[0][1]))
  elif has_self(node, global_ctx):
    return (true, "self." & strVal(node[1]))
  elif is_log_statement(node, global_ctx):
    return (true, "log." & strVal(node[0][1]))
  else:
    return (false, "")


proc find_builtin_keywords(func_body: NimNode, used_keywords: var seq[string], global_ctx: GlobalContext) =

  for child in func_body:
    let (is_kw, kw_key_name) = is_keyword(child, global_ctx)
   
    var
      setter_kw = false
      exemption_list = @[
        "set_" & kw_key_name,
        "set_table_" & kw_key_name,
        "get_table_" & kw_key_name,
      ]

    for proposed_setter_kw in exemption_list:
      if proposed_setter_kw in used_keywords:
        setter_kw = true
    if is_kw and not setter_kw:  # Should be added to globals list.
        used_keywords.add(kw_key_name)
    find_builtin_keywords(child, used_keywords, global_ctx)


proc generate_defines(keywords: seq[string], global_ctx: GlobalContext): (NimNode, Table[string, string]) =
  # Allocate keywords that do not alter their value 
  # during execution of a function e.g. msg.sender, msg.value etc.  
  var stmts = newStmtList()
  var tmp_vars = initTable[string, string]()
  if "msg.sender" in keywords:

    var 
      tmp_var_name = "msg_sender_tmp_variable_alloc"
      tmp_var_node = newIdentNode(tmp_var_name)

    var s = quote do:
      var `tmp_var_node` {.noinit.}: address
      getCaller(addr `tmp_var_node`)

    stmts.add(s)
    tmp_vars["msg.sender"] = tmp_var_name

  if "msg.value" in keywords:
    var tmp_func_name = fmt"msg_value_func"
    stmts.add(parseStmt("proc " & tmp_func_name & """(): uint128 =
      var ba {.noinit.}: array[16, byte]
      getCallValue(addr ba)
      var val {.noinit.}: Stuint[128]
      {.pragma: restrict, codegenDecl: "$# __restrict $#".}
      let r_ptr {.restrict.} = cast[ptr array[128, byte]](addr val)
      for i, b in ba:
        r_ptr[i] = b
      return val
    """))
    tmp_vars["msg.value"] = tmp_func_name

  for kw in keywords:
    if kw.startsWith("log."):
      var (new_proc, new_proc_name) = generate_log_func(kw, global_ctx)
      tmp_vars[kw] = new_proc_name
      stmts.add(new_proc)
    elif kw.startsWith("set_self."):
      var (new_proc, new_proc_name) = generate_storage_set_func(kw, global_ctx)
      tmp_vars[kw] = new_proc_name
      stmts.add(new_proc)
    elif kw.startsWith("set_table_self."):
      var (new_proc, new_proc_name) = generate_storage_table_set_func(kw, global_ctx)
      tmp_vars[kw] = new_proc_name
      stmts.add(new_proc)
    elif kw.startsWith("get_table_self."):
      var (new_proc, new_proc_name) = generate_storage_table_get_func(kw, global_ctx)
      tmp_vars[kw] = new_proc_name
      stmts.add(new_proc)
    elif kw.startsWith("self."):
      var (new_proc, new_proc_name) = generate_storage_get_func(kw, global_ctx)
      tmp_vars[kw] = new_proc_name
      stmts.add(new_proc)
  return (stmts, tmp_vars)


proc check_keyword_defines(keywords_used: seq[string], local_ctx: LocalContext) =
  for keyword in keywords_used:
    var base = keyword.replace("set_", "").replace("get_", "").replace("table_", "")
    if "." in base:
      base = base.split(".")[0]
    if not (base in local_ctx.sig.pragma_base_keywords):
      raiseParserError(
        fmt"Base Keyword {{.{base}.}} needs to be placed in the pragma of function '{local_ctx.sig.name}'.", 
        local_ctx.sig.line_info
      )


proc get_keyword_defines*(proc_def: NimNode, global_ctx: GlobalContext, local_ctx: LocalContext): (NimNode, Table[string, string]) =
  var
    keywords_used: seq[string]
  find_builtin_keywords(proc_def, keywords_used, global_ctx)
  echo keywords_used
  echo "$%$%$%$%$%^^^^^^^^"
  keywords_used = deduplicate(keywords_used)
  check_keyword_defines(keywords_used, local_ctx)
  let (global_define_stmts, global_keyword_map) = generate_defines(keywords_used, global_ctx)
  return (global_define_stmts, global_keyword_map)


proc get_next_storage_node(kw_key_name: string, global_keyword_map: Table[string, string], current_node: NimNode): NimNode =
  echo global_keyword_map
  echo kw_key_name
  echo "%%.."
  if kw_key_name.startsWith("self."):
    return nnkCall.newTree(
      newIdentNode(global_keyword_map[kw_key_name])
    )
  elif kw_key_name.startsWith("set_self."):
    return nnkCall.newTree(
      newIdentNode(global_keyword_map[kw_key_name]),
      current_node[1]
      )
  elif kw_key_name.startsWith("get_table_self."):
    var 
      keys: seq[NimNode]
      call_func = nnkCall.newTree(
        newIdentNode(global_keyword_map[kw_key_name]),
      )
    extract_keys(current_node, keys)
    for param in keys[1..keys.len - 1]:
      call_func.add(param)
    return call_func
  elif kw_key_name.startsWith("set_table_self."):
    var 
      keys: seq[NimNode]
      call_func = nnkCall.newTree(
        newIdentNode(global_keyword_map[kw_key_name]),
      )
    extract_keys(current_node[0], keys)
    for param in keys[1..^1]:
      call_func.add(param)
    call_func.add(current_node[1])  # val param
    return call_func
  else:
    raise newException(ParserError, "Unknown global self keyword")


proc replace_keywords*(ast_node: NimNode, global_keyword_map: Table[string, string], global_ctx: GlobalContext): NimNode  =
  var
    TMP_VAR_KEYWORDS = @["msg.sender"]
    TMP_FUNC_KEYWORDS = @["msg.value"]

  var res_node = copyNimNode(ast_node)
  for child in ast_node:
    var next: NimNode
    let (is_kw, kw_key_name) = is_keyword(child, global_ctx)
    if is_kw:
      if kw_key_name.startsWith("log."):
        next = generate_next_call_log_node(kw_key_name, global_keyword_map, child)
      elif "self." in kw_key_name:
          next = get_next_storage_node(kw_key_name, global_keyword_map, child)
      elif kw_key_name in TMP_FUNC_KEYWORDS:
        next = nnkCall.newTree(
          newIdentNode(global_keyword_map[kw_key_name])
        )
      elif kw_key_name in TMP_VAR_KEYWORDS:
        next = newIdentNode(global_keyword_map[kw_key_name])
      else:
        raise newException(ParserError, "No replacement specified for " & kw_key_name & " keyword")
    else:
      next = child
    res_node.add(replace_keywords(next, global_keyword_map, global_ctx))
  return res_node
