import macros
import stint
import system
import strformat
import tables
import endians
import sequtils
import strutils

import ./function_signature, ./builtin_keywords, ./types, ./utils


proc get_func_name(proc_def: NimNode): string =
  var func_name = ""
  for child in proc_def:
    if child.kind == nnkPostfix:
      func_name = strVal(child[1])
      break
    if child.kind == nnkIdent:
      func_name = strVal(child)
      break
  return func_name


proc get_local_input_type_conversion(tmp_var_name, tmp_var_converted_name, var_type: string): (NimNode, NimNode) =
  case var_type
  of "uint256", "uint128", "wei_value":
    var base_stint_type = "Uint256"
    if var_type in @["uint128", "wei_value"]:
      base_stint_type = "UInt128"
    var convert_node = nnkLetSection.newTree(
      nnkIdentDefs.newTree(
        newIdentNode(tmp_var_converted_name),
        newIdentNode(var_type),
        nnkCall.newTree(
          nnkDotExpr.newTree(
            newIdentNode(base_stint_type),
            newIdentNode("fromBytesBE")
          ),
          newIdentNode(tmp_var_name)
        )
      )
    )
    var ident_node = newIdentNode(tmp_var_converted_name)
    return (ident_node, convert_node)
  of "bytes32":
    return (newIdentNode(tmp_var_name), newEmptyNode())
  of "address":
    var convert_node = parseStmt(unindent(fmt"""
      var {tmp_var_converted_name}: address
      copy_into_ba({tmp_var_converted_name}, 12, {tmp_var_name})
      """
    ))
    return (newIdentNode(tmp_var_converted_name), convert_node)
  else:
    raise newException(ParserError, fmt"get_local_input_type_conversion: Unknown '{var_type}' type supplied!")


proc get_local_output_type_conversion(tmp_result_name, tmp_result_converted_name, var_type: string): (NimNode, NimNode) =
  case var_type
  of "uint256":
    var ident_node = newIdentNode(tmp_result_converted_name)
    var conversion_node = nnkVarSection.newTree(
        nnkIdentDefs.newTree(
        newIdentNode(tmp_result_converted_name),
        newEmptyNode(),
          nnkDotExpr.newTree(
            newIdentNode(tmp_result_name),
            newIdentNode("toByteArrayBE")
          )
        )
      )
    return (ident_node, conversion_node)
  of "uint128", "wei_value":
    var ident_node = newIdentNode(tmp_result_converted_name)
    var conversion_node = parseStmt(unindent(fmt"""
      var {tmp_result_converted_name} {{.noinit.}}: array[32, byte]
      {tmp_result_converted_name}[16..31] = toByteArrayBE({tmp_result_name})
    """))
    return (ident_node, conversion_node)
  of "address":
    var ident_node = newIdentNode(tmp_result_converted_name)
    var conversion_node = nnkStmtList.newTree(
      nnkVarSection.newTree(  # var a: array[32, byte]
        nnkIdentDefs.newTree(
          newIdentNode(tmp_result_converted_name),
          nnkBracketExpr.newTree(
            newIdentNode("array"),
            newLit(32),
            newIdentNode("byte"),
          ),
          newEmptyNode()
        )
      ),
      nnkAsgn.newTree(  # a[11..31] = tmp_addr
        nnkBracketExpr.newTree(
          newIdentNode(tmp_result_converted_name),
          nnkInfix.newTree(
            newIdentNode(".."),
            newLit(12),
            newLit(31)
          )
        ),
        newIdentNode(tmp_result_name)
      )
    )
    return (ident_node, conversion_node)
    # return (newIdentNode(tmp_result_name), newEmptyNode())
  of "bytes32":
    return (newIdentNode(tmp_result_name), newEmptyNode())
  else:
    raise newException(ParserError, fmt"Unknown '{var_type}' type supplied!")


proc generate_context(proc_def: NimNode, global_ctx: GlobalContext): LocalContext =
  var ctx = LocalContext()
  ctx.name = get_func_name(proc_def)
  ctx.sig = generate_function_signature(proc_def, global_ctx)
  (ctx.keyword_define_stmts, ctx.global_keyword_map) = get_keyword_defines(proc_def, global_ctx, ctx)
  return ctx

proc handle_global_storage_tables(table_def: NimNode, global_ctx :var GlobalContext, slot_number: var int)  =
  expectKind(table_def, nnkCall)
  var
    key_types: seq[string]
    var_name = strVal(table_def[0])
    var_types = table_def[1][0]

  for x in var_types[1..var_types.len - 1]:
    key_types.add(strVal(x))

  var var_struct = VariableType(
    name: var_name,
    var_type: "StorageTable",
    key_types: key_types,
    slot: slot_number
  )
  global_ctx.global_variables[var_name] = var_struct
  inc(slot_number)


proc handle_global_defines(var_section: NimNode, global_ctx :var GlobalContext, slot_number: var int)  =

  for child in var_section:
    case child.kind
    of nnkIdentDefs:
      var create_getter = false
      if (child[0].kind, child[1].kind) == (nnkPostfix, nnkIdent) and strVal(child[0][0]) == "*":
        # create getter.
        create_getter = true
      elif (child[0].kind, child[1].kind) != (nnkIdent, nnkIdent):
        raiseParserError(
          "Global variables need to be defined as 'var_name: var_type'",
          child
        )

      var
        var_node = if create_getter: child[0][1] else: child[0]
        var_name = strVal(var_node)
        var_type = strVal(child[1])

      check_valid_variable_name(var_node, global_ctx)
      # echo var_name & " -> " & var_type
      if var_name in global_ctx.global_variables:
        raiseParserError(
          fmt"Global variable '{var_name}' has already been defined",
          child
        )
      var var_struct = VariableType(
        name: var_name,
        var_type: var_type,
        slot: slot_number
      )
      if create_getter:
        global_ctx.getter_funcs.add(var_struct)
      global_ctx.global_variables[var_name] = var_struct
      inc(slot_number)
    else:
      raiseParserError(
        fmt"Unsupported statement in global var section",
        child
      )


proc handle_event_defines(event_def: NimNode, global_ctx: var GlobalContext) =
  expectKind(event_def, nnkProcDef)
  if event_def[6].kind != nnkEmpty:
    raiseParserError("Event definition expect no function bodies", event_def)
  if not (event_def[4].kind == nnkPragma and strVal(event_def[4][0]) == "event"):
    raiseParserError("Events require event pragma e.g. 'proc EventName(a: uint256) {.event.}'", event_def)

  var event_name = strVal(event_def[0])
  if event_name in global_ctx.events:
    raiseParserError(fmt"Event '{event_name}' has already been defined.", event_def)
  var 
    event_sig = EventSignature(
      name: event_name,
      definition: event_def
    )
    param_position = 0
  
  for child in event_def:
    if child.kind == nnkFormalParams:
      var params = child
      for param in params:
        if param.kind == nnkIdentDefs:
          if param[0].kind == nnkPragmaExpr and param[0][1].kind == nnkPragma:
            var
              pragma_expr = param[0][1][0]
            if pragma_expr.kind != nnkIdent or strVal(pragma_expr) != "indexed":
                raiseParserError("Unsupported pragma", pragma_expr)
            event_sig.inputs.add(EventType(
              name: strVal(param[0][0]),
              var_type: strVal(param[1]),
              indexed: true,
              param_position: param_position
            ))
          elif param[0].kind == nnkIdent:
            check_valid_variable_name(param[0], global_ctx)
            var param_name = strVal(param[0])
            event_sig.inputs.add(EventType(
              name: param_name,
              var_type: strVal(param[1]),
              indexed: false,
              param_position: param_position
            ))
          else:
            raiseParserError("Unsupported event parameter type", params)
          param_position += 1
  if len(event_sig.inputs) == 0:
    raiseParserError("Event requires parameters", event_def)
  if filter(event_sig.inputs, proc(x: EventType): bool = x.indexed).len > 3:
    raiseParserError("Can only have 3 indexed parameters", event_def)
  global_ctx.events[event_name] = event_sig


template get_util_functions() {.dirty.} =
  proc copy_into_ba(to_ba: var auto, offset: int, from_ba: auto) =
    for i, x in from_ba:
      if offset + i > sizeof(to_ba) - 1:
        break
      to_ba[offset + i] = x

  func to_bytes32(a: uint128): bytes32 =
    var
      tmp: bytes32
    copy_into_ba(tmp, 0, a.toBytesLE)
    tmp

  func to_uint128(a: bytes32): uint128 =
    var
      tmp_ba: array[32, byte]
      tmp: uint128
    copy_into_ba(tmp_ba, 0, a)
    tmp = fromBytes(Uint128, tmp_ba)
    tmp

  proc assertNotPayable() =
    var b {.noinit.}: array[16, byte]
    getCallValue(addr b)
    if Uint128.fromBytesBE(b) > 0.stuint(128):
      revert(nil, 0)

  proc exitMessage(s: string) =
    revert(cstring(s), s.len.int32)

  proc concat[I1, I2: static[int]; T](a: array[I1, T], b: array[I2, T]): array[I1 + I2, T] =
    result[0..a.high] = a
    result[a.len..result.high] = b

  proc getHashedKey[N](table_id: int32, key: array[N, byte]): bytes32 =
    type CombinedKey {.packed.} = object
      table_id: int32
      key: array[N, byte]
    var
      hashed_key {.noinit.}: bytes32
      combined_key: CombinedKey
      sha256_address: array[20, byte]

    sha256_address[19] = 2'u8
    combined_key.table_id = table_id
    combined_key.key = key

    var res = call(
      getGasLeft(), # gas
      addr sha256_address,  # addressOffset (ptr)
      nil,  # valueOffset (ptr)
      addr combined_key, # dataOffset (ptr)
      sizeof(combined_key).int32, # dataLength
    )
    if res == 1:  # call failed
      exitMessage("Could not call sha256 in setTableValue")
      # raise newException(Exception, "Could not call sha256 in setTableValue")
    if getReturnDataSize() != 32.int32:
        exitMessage("Could not call sha256, Incorrect return size")
    returnDataCopy(addr hashed_key, 0.int32, 32.int32)

    hashed_key  # return

  proc setTableValue[N](table_id: int32, key: array[N, byte], value: var bytes32) =
    var hashed_key = getHashedKey(table_id, key)
    storageStore(hashed_key, addr value)

  proc getTableValue[N](table_id: int32, key: array[N, byte], ): bytes32 =
    var
      value: bytes32
      hashed_key: bytes32 = getHashedKey(table_id, key)
    storageLoad(hashed_key, addr value)
    value  # return


proc get_getter_func(var_struct: VariableType): NimNode =
  let
    proc_name_node = newIdentNode(var_struct.name)
    proc_return_type_node = newIdentNode(var_struct.var_type)
    storage_name_node = newIdentNode(var_struct.name)
  quote do:
    proc `proc_name_node`*():`proc_return_type_node` {.self.} = ## generated getter
      self.`storage_name_node`


proc handle_contract_interface(in_stmts: NimNode): NimNode = 
  var
    main_out_stmts = newStmtList()
    function_signatures = newSeq[FunctionSignature]()
    global_ctx = GlobalContext()

  main_out_stmts.add(getAst(get_util_functions()))
  # var util_funcs = get_util_functions()
  # discard util_funcs
  var slot_number = 0
  for child in in_stmts:
    if child.kind == nnkCall and child[1].kind == nnkStmtList and child[1][0].kind == nnkBracketExpr:
      if strVal(child[1][0][0]) == "StorageTable":
        handle_global_storage_tables(child, global_ctx, slot_number)
      else:
        raiseParserError("Unsupported global definition.", child)
    if child.kind == nnkVarSection:
      handle_global_defines(child, global_ctx, slot_number)

  # Inject getter functions if needed.
  if  global_ctx.getter_funcs.len > 0:
    for var_struct in global_ctx.getter_funcs:
      in_stmts.add(get_getter_func(var_struct))

  for child in in_stmts:
    case child.kind:
    of nnkProcDef:
      if child[6].kind == nnkEmpty:  # Event definition.
        handle_event_defines(child, global_ctx)
        continue
      var ctx = generate_context(child, global_ctx)
      function_signatures.add(ctx.sig)
      var new_proc_def = strip_pragmas(child)
      new_proc_def = replace_keywords(
        ast_node=new_proc_def,
        global_keyword_map=ctx.global_keyword_map,
        global_ctx=global_ctx
      )
      # Insert global defines.
      new_proc_def[6].insert(0, ctx.keyword_define_stmts)
      main_out_stmts.add(new_proc_def)
    else:
      discard
  
  if filter(function_signatures, proc(x: FunctionSignature): bool = not x.is_private).len == 0:
    raise newException(
      ParserError,
      "No public functions have been defined, use * postfix to annotate public functions. e.g. proc myfunc*(a: uint256)"
    )

  # Build Main Entrypoint.
  var out_stmts = newStmtList()
  out_stmts.add(
    nnkVarSection.newTree( # var selector: uint32
      nnkIdentDefs.newTree(
        newIdentNode("selector"),
        newIdentNode("uint32"),
        newEmptyNode()
      )
    ),
    nnkCall.newTree(  # callDataCopy(selector, 0)
      newIdentNode("callDataCopy"),
      newIdentNode("selector"),
      newLit(0)
    ),
  )

  # Convert selector.
  out_stmts.add(
    nnkStmtList.newTree(
      newCall(
        bindSym"bigEndian32",
        nnkCommand.newTree(
          newIdentNode("addr"),
          newIdentNode("selector")
        ),
        nnkCommand.newTree(
          newIdentNode("addr"),
          newIdentNode("selector")
        )
      )
    )
  )

  var selector_CaseStmt = nnkCaseStmt.newTree(
    newIdentNode("selector")
  )

  # Build function selector.
  for func_sig in function_signatures:
    if func_sig.is_private:
      continue
    echo "Building " & func_sig.method_sig
    var call_and_copy_block = nnkStmtList.newTree()
    var call_to_func = nnkCall.newTree(
      newIdentNode(func_sig.name)
    )
    var start_offset = 4

    if not func_sig.payable:
      call_and_copy_block.add(parseStmt("assertNotPayable()"))

    for idx, param in func_sig.inputs:
      var
        static_param_size = get_byte_size_of(param.var_type)
        tmp_var_name = fmt"{func_sig.name}_param_{idx}"
        tmp_var_converted_name = fmt"{func_sig.name}_param_{idx}_converted"
      # var <tmp_name>: <type>
      # callDataCopy(addr <tmp_name>, <offset>, <len>)
      call_and_copy_block.add(
        parseStmt(unindent(fmt"""
          var {tmp_var_name} {{.noinit.}}: array[{static_param_size}, byte]
          callDataCopy(addr {tmp_var_name}, {start_offset}, {static_param_size})
        """)
        )
      )

      # Get conversion code if necessary.
      let (ident_node, convert_node) = get_local_input_type_conversion(
        tmp_var_name,
        tmp_var_converted_name,
        param.var_type
      )
      if  not (ident_node.kind == nnkEmpty):
        if not (convert_node.kind == nnkEmpty):
          call_and_copy_block.add(convert_node)
        call_to_func.add(ident_node)
      start_offset += static_param_size

    # Handle returned data from function.
    if len(func_sig.outputs) == 0:
      # Add final function call.
      call_and_copy_block.add(call_to_func)
      call_and_copy_block.add(
        nnkStmtList.newTree(
          nnkCall.newTree(
            newIdentNode("finish"),
            newNilLit(),
            newLit(0)
          )
        )
      )
    elif len(func_sig.outputs) == 1:
      var assign_result_block = nnkAsgn.newTree()
      var param = func_sig.outputs[0]
      var idx = 0
      # create placeholder variables
      var tmp_result_name = fmt"{func_sig.name}_result_{idx}"
      var tmp_result_converted_name = tmp_result_name & "_arr"
      call_and_copy_block.add(
        nnkVarSection.newTree(
          nnkIdentDefs.newTree(
            nnkPragmaExpr.newTree(
              newIdentNode(tmp_result_name),
              nnkPragma.newTree(
                newIdentNode("noinit")
              )
            ),
            newIdentNode(param.var_type),
            newEmptyNode()
          )
        )
      )
      assign_result_block.add(newIdentNode(tmp_result_name))
      assign_result_block.add(call_to_func)

      call_and_copy_block.add(assign_result_block)
      let (tmp_conversion_ident_node, conversion_node) = get_local_output_type_conversion(
        tmp_result_name,
        tmp_result_converted_name,
        param.var_type
      )

      call_and_copy_block.add(conversion_node)

      call_and_copy_block.add(
        nnkCall.newTree(
          newIdentNode("finish"),
          nnkCommand.newTree(
            newIdentNode("addr"),
            tmp_conversion_ident_node
          ),
          newLit(get_byte_size_of(param.var_type))
        )
      )
    else:
      raiseParserError(
        "Can only handle functions with a single variable output ATM.",
        func_sig.line_info
      )

    selector_CaseStmt.add(
      nnkOfBranch.newTree(  # of 0x<>'u32:
        parseExpr( "0x" & func_sig.method_id & "'u32"),
        call_and_copy_block
      )
    )

  # Add default revert into selector.
  selector_CaseStmt.add(
    nnkElse.newTree(
      nnkStmtList.newTree(
        nnkDiscardStmt.newTree(  # discard
          newEmptyNode()
        )
      )
    )
  )
  out_stmts.add(selector_CaseStmt)
  out_stmts.add(nnkCall.newTree(
      newIdentNode("revert"),
      newNilLit(),
      newLit(0)
    )
  )

  # Build Main Func
  # proc main() {.exportwasm.} =
  # if getCallDataSize() < 4:
  #     revert(nil, 0)

  var main_func = nnkStmtList.newTree(
    nnkProcDef.newTree(
      newIdentNode("main"),
      newEmptyNode(),
      newEmptyNode(),
      nnkFormalParams.newTree(
        newEmptyNode()
      ),
      nnkPragma.newTree(
        newIdentNode("exportwasm")
      ),
      newEmptyNode(),
      out_stmts,
    )
  )
  main_out_stmts.add(main_func)
  # echo out_stmts

  # build selector:
  # keccak256("balance(address):(uint64)")[0, 4]

  return main_out_stmts


macro contract*(contract_name: string, proc_def: untyped): untyped =
  echo contract_name
  # echo "Before:"
  # echo treeRepr(proc_def)
  expectKind(proc_def, nnkStmtList)
  var stmtlist = handle_contract_interface(proc_def)
  echo "Final Contract Code:"
  echo repr(stmtlist)
  return stmtlist
