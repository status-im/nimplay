import macros
import stint
import system
import strformat
import tables

import ./eth_abi_utils

type uint256* = StUint[256]
type int128* = StInt[128]
type ParserError = object of Exception



proc handleProcDef(func_stmt: NimNode): (string, NimNode) =
    var func_name = ""
    for child in func_stmt:
        if child.kind == nnkIdent:
            func_name = strVal(child)
    return (func_name, func_stmt)


proc get_byte_size_of(type_str: string): int =
    let BASE32_TYPES_NAMES: array = [
        "uint256",
        "int128"
    ]
    if type_str in BASE32_TYPES_NAMES:
        return 32
    else:
        raise newException(Exception, fmt"Unknown '{type_str}' type supplied!")


func get_bit_size_of(type_str: string): int =
    get_byte_size_of(type_str) * 8


proc handleContractInterface(stmts: NimNode): NimNode = 
    var main_out_stmts = newStmtList()
    var function_signatures = newSeq[FunctionSignature]()

    for child in stmts:
        case child.kind:
        of nnkProcDef:
            let (func_name, out_def) = handleProcDef(child)
            function_signatures.add(generate_function_signature(child))
            main_out_stmts.add(child)
        else:
            discard
            # raise newException(ParserError, ">> Invalid stmt \"" &  getTypeInst(child) & "\" not supported in contract block")

    # var a = get_abi_json(function_signatures)
    # var selector_case = newNimNode(nnkCaseStmt)   
    # selector_case.add(newIdentNode("selector"))
    
    # Create main func / selector.
    # let main_func = parseStmt(
    #     """
    #         proc main() {.exportwasm.} =
    #             if getCallDataSize() < 4:
    #                 revert(nil, 0)
    #     """
    # )
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
        echo "Building " & func_sig.method_id
        var call_and_copy_block = nnkStmtList.newTree()
        var call_to_func = nnkCall.newTree(
            newIdentNode(func_sig.name)
        )
        var start_offset = 4

        for idx, param in func_sig.inputs:
            var static_param_size = get_byte_size_of(param.var_type)
            var tmp_var_name = fmt"{func_sig.name}_param_{idx}"
            var tmp_var_converted = fmt"{func_sig.name}_param_{idx}_converted"
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
            call_and_copy_block.add(
                nnkLetSection.newTree(  # let c: uint256 = Uint256.fromBytesBE(b), TODO: handle different types.
                    nnkIdentDefs.newTree(
                        newIdentNode(tmp_var_converted),
                        newIdentNode(param.var_type),
                        nnkCall.newTree(
                            nnkDotExpr.newTree(
                                newIdentNode("Uint256"),
                                newIdentNode("fromBytesBE")
                            ),
                            newIdentNode(tmp_var_name)
                        )
                    )
                )
            )
            call_to_func.add(newIdentNode(tmp_var_converted))
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
            var tmp_var_res_name = fmt"{func_sig.name}_result_{idx}"
            var tmp_var_res_name_array = tmp_var_res_name & "_arr"
            call_and_copy_block.add(
                nnkVarSection.newTree(
                    nnkIdentDefs.newTree(
                        nnkPragmaExpr.newTree(
                            newIdentNode(tmp_var_res_name),
                            nnkPragma.newTree(
                                newIdentNode("noinit")
                            )
                        ),
                        newIdentNode(param.var_type),
                        newEmptyNode()
                    )
                )
            )
            assign_result_block.add(newIdentNode(tmp_var_res_name))
            assign_result_block.add(call_to_func)
            call_and_copy_block.add(assign_result_block)
            call_and_copy_block.add(
                nnkVarSection.newTree(
                    nnkIdentDefs.newTree(
                      newIdentNode(tmp_var_res_name_array),
                      newEmptyNode(),
                      nnkDotExpr.newTree(
                        newIdentNode(tmp_var_res_name),
                        newIdentNode("toByteArrayBE")
                      )
                    )
                  )
            )
            call_and_copy_block.add(
                nnkCall.newTree(
                    newIdentNode("finish"),
                    nnkCommand.newTree(
                        newIdentNode("addr"),
                        newIdentNode(tmp_var_res_name_array)
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
    echo treeRepr(proc_def)
    expectKind(proc_def, nnkStmtList)
    var stmtlist = handleContractInterface(proc_def)
    # echo "After:"
    # echo treeRepr(stmtlist)
    return stmtlist
