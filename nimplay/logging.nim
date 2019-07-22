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


proc get_indexed_param_locations(event_sig: EventSignature): seq[int] =
  var
    locations: seq[int]
    i = 0
  for event in event_sig.inputs:
    if event.indexed:
      locations.add(event.param_position)
    i += 1
  locations  # return


proc get_param_copiers(event_sig: EventSignature, buffer_name: string): (NimNode, Table[string, int]) =
  var
    copy_stmts = newStmtList()
    current_abi_offset = 0
    position_map: Table[string, int]
  for event_param in event_sig.inputs:
    var (type_offset, converted_param_name) = get_converter_ident(event_param.name, event_param.var_type)
    var abi_bytearr_offset = 32 + current_abi_offset + type_offset
    position_map[event_param.name] = 32 + current_abi_offset
    copy_stmts.add(
      parseStmt(
      fmt"""
      copy_into_ba({buffer_name}, {abi_bytearr_offset}, {converted_param_name})
      """)
    )
    current_abi_offset += get_byte_size_of(event_param.var_type)
  (copy_stmts, position_map)


proc get_new_proc_def(event_sig: EventSignature): NimNode =
  # copyNimTree(func_def)
  var
    param_list: seq[string]
  for param in event_sig.inputs:
    param_list.add(fmt"{param.name}:{param.var_type}")
  var
    param_str = param_list.join(";")
    new_proc = parseExpr(
      fmt"""
      proc {event_sig.name} ({param_str}) =
        discard
      """
    )
  echo treeRepr(new_proc)
 
  new_proc



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
    event_func_def = get_new_proc_def(event_sig)
    total_data_buffer_size = get_total_data_buffer_size(func_def)
    data_size = total_data_buffer_size - 32
    event_id_int_arr = hexstr_to_intarray[32](getKHash(generate_method_sig(event_sig)))
    data_buffer_name = "output_buffer"
    indexed_param_locations = get_indexed_param_locations(event_sig)


  # Create function definition.

  event_func_def[0] =  newIdentNode(new_proc_name)
  event_func_def[4] = newEmptyNode()
  # Create data section buffer.
  event_func_def[6] = parseStmt(
    fmt"var {data_buffer_name} {{.noinit.}}: array[{total_data_buffer_size}, byte]"
  )

  var 
    event_sig_int_arr = nnkBracket.newTree()
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
  var (copiers, position_maps) = get_param_copiers(event_sig, data_buffer_name)
  event_func_def[6].add(
    copiers
  )
  # Create topic parameters (1-3, after indexed function sig).
  var 
    topic_list: seq[string]
    topic_count = 0
  for i, param in event_sig.inputs:
    if param.indexed:
      topic_list.add(fmt"addr {data_buffer_name}[{intToStr(position_maps[param.name])}]")
      topic_count += 1
  # Add nils
  for _ in 1..(3 - len(topic_list)):
    topic_list.add("nil")
  # Call Log
  event_func_def[6].add(
    parseStmt(
    fmt"""
    log(addr {data_buffer_name}[32], {data_size}.int32, {1 + topic_count}.int32, addr {data_buffer_name}[0], {topic_list.join(",")})
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
