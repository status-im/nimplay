import macros
import stint
import system
import strformat
import tables
import endians


import ./eth_abi_utils, ./builtin_keywords

type uint256* = StUint[256]
type int128* = StInt[128]
type address* = array[20, byte]
type bytes32* = array[32, byte]

type ParserError = object of Exception

type
    LocalContext* = object
        # Name of the function.
        name: string
        # Function signature, used for function selection and ABI encoding / decoding.
        sig: FunctionSignature
        # Global temp variables create at beginning of the function.
        keyword_define_stmts: NimNode
        # Map of temp variables that have to be replaced by.
        global_keyword_map: Table[string, string] 


proc get_func_name(proc_def: NimNode): string =
    var func_name = ""
    for child in proc_def:
        if child.kind == nnkIdent:
            func_name = strVal(child)
    return func_name


proc get_byte_size_of(type_str: string): int =
    let BASE32_TYPES_NAMES: array = [
        "uint256",
        "int128",
        "address"
    ]
    if type_str in BASE32_TYPES_NAMES:
        return 32
    else:
        raise newException(ParserError, fmt"Unknown '{type_str}' type supplied!")


func get_bit_size_of(type_str: string): int =
    get_byte_size_of(type_str) * 8


proc get_local_input_type_conversion(tmp_var_name, tmp_var_converted_name, var_type: string): (NimNode, NimNode) =
    case var_type
    of "uint256":
        var convert_node = nnkLetSection.newTree(
            nnkIdentDefs.newTree(
                newIdentNode(tmp_var_converted_name),
                newIdentNode(var_type),
                nnkCall.newTree(
                    nnkDotExpr.newTree(
                        newIdentNode("Uint256"),
                        newIdentNode("fromBytesBE")
                    ),
                    newIdentNode(tmp_var_name)
                )
            )
        )
        var ident_node = newIdentNode(tmp_var_converted_name)
        return (ident_node, convert_node)
    of "address":
        return (newEmptyNode(), newEmptyNode())
    else:
        raise newException(ParserError, fmt"Unknown '{var_type}' type supplied!")


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
    else:
        raise newException(ParserError, fmt"Unknown '{var_type}' type supplied!")


proc generate_context(proc_def: NimNode): LocalContext =
    var ctx = LocalContext()
    ctx.name = get_func_name(proc_def)
    ctx.sig = generate_function_signature(proc_def)
    (ctx.keyword_define_stmts, ctx.global_keyword_map) = get_keyword_defines(proc_def)
    return ctx


proc handle_contract_interface(stmts: NimNode): NimNode = 
    var main_out_stmts = newStmtList()
    var function_signatures = newSeq[FunctionSignature]()

    for child in stmts:
        case child.kind:
        of nnkProcDef:
            var ctx = generate_context(child)
            function_signatures.add(ctx.sig)
            var new_proc_def = replace_keywords(
                ast_node=child,
                global_keyword_map=ctx.global_keyword_map
            )
            # Insert global defines.
            new_proc_def[6].insert(0, ctx.keyword_define_stmts)
            main_out_stmts.add(new_proc_def)
        else:
            discard
            # raise newException(ParserError, ">> Invalid stmt \"" &  getTypeInst(child) & "\" not supported in contract block")

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

    # selector_CaseStmt.add(newIdentNode("selector"))
    # nnkStmtList.newTree(
    #   nnkCall.newTree(
    #     newIdentNode("hello"),
    #     newIdentNode("a")
    #   )
    # )

    for func_sig in function_signatures:
        echo "Building " & func_sig.method_sig
        var call_and_copy_block = nnkStmtList.newTree()
        var call_to_func = nnkCall.newTree(
            newIdentNode(func_sig.name)
        )
        var start_offset = 4

        for idx, param in func_sig.inputs:
            var static_param_size = get_byte_size_of(param.var_type)
            var tmp_var_name = fmt"{func_sig.name}_param_{idx}"
            var tmp_var_converted_name = fmt"{func_sig.name}_param_{idx}_converted"
            # var <tmp_name>: <type>
            call_and_copy_block.add(
                nnkVarSection.newTree(
                    nnkIdentDefs.newTree(
                        newIdentNode(tmp_var_name),
                        nnkBracketExpr.newTree(
                            newIdentNode("array"),
                            newLit(static_param_size),
                            newIdentNode("byte")
                        ),
                        newEmptyNode()
                    )
                )
            )
            # callDataCopy(addr <tmp_name>, <offset>, <len>)
            call_and_copy_block.add(
                nnkCall.newTree(
                    newIdentNode("callDataCopy"),
                    nnkCommand.newTree(
                      newIdentNode("addr"),
                      newIdentNode(tmp_var_name)
                    ),
                    newLit(start_offset),
                    newLit(static_param_size)
                )
            )
            
            # Get conversion code if necessary.
            let (ident_node, convert_node) = get_local_input_type_conversion(
                tmp_var_name,
                tmp_var_converted_name,
                param.var_type
            )
            if  not (ident_node.kind == nnkEmpty):
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

            # if conversion_node.kind == nnkStmtList:
            #     for child in conversion_node:
            #         call_and_copy_block.add(child)
            # else:
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
            raise newException(
                Exception, 
                "Can only handle function with a single variable output ATM."
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
                # nnkCall.newTree(
                #     newIdentNode("revert"),
                #     newNilLit(),
                #     newLit(0)
                # )
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

#     out_stmts.add(
#         parseStmt("""
# if getCallDataSize() < 4:
#     revert(nil, 0)
#         """
#         )
#     )
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
    # echo "After:"
    # echo treeRepr(stmtlist)
    return stmtlist
