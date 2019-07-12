import 
  macros, strutils, strformat, tables
import 
  ./types, ./utils


proc get_total_ba_size(proc_def: NimNode): int =
  var total_size = 0
  for child in proc_def:
    if child.kind == nnkFormalParams:
      for param in child:
        if param.kind == nnkIdentDefs:
          total_size += get_byte_size_of(strVal(param[1]))
  total_size


proc generate_log_func*(log_keyword: string, global_ctx: GlobalContext): (NimNode, string) =
  var
    event_name = log_keyword.split(".")[1]
    new_proc_name = fmt"log_{event_name}"
    func_def = global_ctx.events[event_name].definition
    event_func_def = copyNimTree(func_def)
    total_abi_ba_size = get_total_ba_size(func_def)
  event_func_def[0] = newIdentNode(new_proc_name)
  event_func_def[4] = newEmptyNode()
  # event_func_def[6] = nnkStmtList.newTree(
  #     nnkDiscardStmt.newTree(
  #     newEmptyNode()
  #   )
  # )
  event_func_def[6] = parseStmt(fmt"""
    var out_ba: array[{$total_abi_ba_size}, byte]
  """)
  return (event_func_def, new_proc_name)


proc generate_next_call_log_node*(kw_key_name: string, global_keyword_map: Table[string, string], current_node: NimNode): NimNode =
  if kw_key_name.startsWith("log."):
    let event_func_name = kw_key_name.split(".")[1]
    var new_call = copyNimTree(current_node)
    new_call[0] = newIdentNode(global_keyword_map[kw_key_name])
    return new_call
  else:
    raise newException(ParserError, fmt"Unknown '{kw_key_name}' log keyword supplied")
