import 
  macros, strutils, strformat, tables

import 
  ./types, ./utils, ./function_signature


proc get_total_data_buffer_size(proc_def: NimNode): int =
  var total_size = 0
  for child in proc_def:
    if child.kind == nnkFormalParams:
      for param in child:
        if param.kind == nnkIdentDefs:
          total_size += get_byte_size_of(strVal(param[1]))
  # Total output size -> 32 byte event sig + total parameter size.
  total_size + 32


proc get_converter_ident(param_name, param_type: string): (int, string) = 
  case param_type:
  of "uint256":
    (0, param_name & ".toByteArrayBE")
  of "uint128":
    (16, param_name & ".toByteArrayBE")
  of "address":
    (32 - 20, param_name)
  else:
    (0, param_name)


proc get_param_copiers(proc_def: NimNode, buffer_name: string): NimNode =
  var
    copy_stmts = newStmtList()
    current_abi_offset = 0
  for child in proc_def:
    if child.kind == nnkFormalParams:
      for param in child:
        if param.kind == nnkIdentDefs:
          var
            type_offset = 0
            param_type = strVal(param[1])
            param_name = strVal(param[0])
          (type_offset, param_name) = get_converter_ident(param_name, param_type)
          copy_stmts.add(
            parseStmt(fmt"""
            copy_into_ba({buffer_name}, {32 + current_abi_offset + type_offset}, {param_name})
            """)
          )
          current_abi_offset += get_byte_size_of(strVal(param[1]))
  copy_stmts


proc generate_log_func*(log_keyword: string, global_ctx: GlobalContext): (NimNode, string) =
  # To make a log statement we allocate a chunk of data memory.
  # This buffer contains:
  # 0-32 contains the 32 byte keccak, this also becomes topic 1 (indexed).
  # 32-N contains the rest of the data portion, the data portion is not indexed.
  var
    event_name = log_keyword.split(".")[1]
    new_proc_name = fmt"log_{event_name}"
    event_sig = global_ctx.events[event_name]
    func_def = event_sig.definition
    event_func_def = copyNimTree(func_def)
    total_data_buffer_size = get_total_data_buffer_size(func_def)
    data_size = total_data_buffer_size - 32
    event_id_int_arr = hexstr_to_intarray[32](getKHash(generate_method_sig(event_sig)))
    data_buffer_name = "output_buffer"

  # Create function definition.
  event_func_def[0] = newIdentNode(new_proc_name)
  event_func_def[4] = newEmptyNode()
  # Create data section buffer.
  event_func_def[6] = parseStmt(
    fmt"var {data_buffer_name} {{.noinit.}}: array[{total_data_buffer_size}, byte]"
  )
  # event_func_def[6] = nnkStmtList.newTree(
  #     nnkVarSection.newTree(
  #     nnkIdentDefs.newTree(
  #       nnkPragmaExpr.newTree(
  #         newIdentNode(data_buffer_name),
  #         nnkPragma.newTree(
  #           newIdentNode("noinit")
  #         )
  #       ),
  #       nnkBracketExpr.newTree(
  #         newIdentNode("array"),
  #         newLit(total_data_buffer_size),
  #         newIdentNode("byte")
  #       ),
  #       newEmptyNode()
  #     )
  #   )
  # )
  var event_sig_int_arr = nnkBracket.newTree()
  for x in event_id_int_arr:
    event_sig_int_arr.add(parseExpr(intToStr(x) & "'u8"))
  event_func_def[6].add(
    newCommentStmtNode("Set event signature")
  )
  event_func_def[6].add(
    nnkAsgn.newTree(
      nnkBracketExpr.newTree(
        newIdentNode(data_buffer_name),
        nnkInfix.newTree(
          newIdentNode(".."),
          newLit(0),
          newLit(31)
        )
      ),
      event_sig_int_arr
    )
  )
  # Copy data into memory
  event_func_def[6].add(
    get_param_copiers(func_def, data_buffer_name)
  )
  # Call Log
  event_func_def[6].add(
    parseStmt(
    fmt"""
    log(addr {data_buffer_name}[32], {data_size}.int32, 1.int32, addr {data_buffer_name}[0], nil, nil, nil)
    """
    )
  )
  return (event_func_def, new_proc_name)


proc generate_next_call_log_node*(kw_key_name: string, global_keyword_map: Table[string, string], current_node: NimNode): NimNode =
  if kw_key_name.startsWith("log."):
    let event_func_name = kw_key_name.split(".")[1]
    var new_call = copyNimTree(current_node)
    new_call[0] = newIdentNode(global_keyword_map[kw_key_name])
    return new_call
  else:
    raise newException(ParserError, fmt"Unknown '{kw_key_name}' log keyword supplied")
