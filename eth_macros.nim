import macros, stint

import ./eth_abi_utils

type uint256* = StUint[256]
type ParserError = object of Exception


proc handleProcDef(func_stmt: NimNode): (string, NimNode) =
    var func_name = ""
    for child in func_stmt:
        if child.kind == nnkIdent:
            func_name = strVal(child)
    return (func_name, func_stmt)


proc handleContractInterface(stmts: NimNode): NimNode = 
    var out_stmts = newStmtList()
    var function_signatures = newSeq[FunctionSignature]()

    for child in stmts:
        case child.kind:
        of nnkProcDef:
            let (func_name, out_def) = handleProcDef(child)
            function_signatures.add(generate_function_signature(child))
            out_stmts.add(child)
        else:
            raise newException(ParserError, "Invalid stmt \"" & treeRepr(child) & "\" not supported in contract block")

    echo "Function Signatures:"
    for f in function_signatures:
        echo f
    echo "^^^"

    # var a = get_abi_json(function_signatures)

    # Create main func / selector.
    # let main_func = parseStmt(
    #     """
    #     proc main() {.exportwasm.} =
    #         if getCallDataSize() < 4:
    #             revert(nil, 0)
    #         var selector: uint32
    #         callDataCopy(selector, 0)
    #     """
    # )
    # out_stmts.add(main_func)

    # build selector:
    # keccak256("balance(address):(uint64)")[0, 4]

    return out_stmts


macro contract*(contract_name: string, proc_def: untyped): untyped =
    echo contract_name
    echo "Before:"
    echo treeRepr(proc_def)
    expectKind(proc_def, nnkStmtList)
    var stmtlist = handleContractInterface(proc_def)
    echo "After:"
    echo treeRepr(stmtlist)
    return stmtlist
