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
            discard
            # raise newException(ParserError, ">> Invalid stmt \"" &  getTypeInst(child) & "\" not supported in contract block")

    # var a = get_abi_json(function_signatures)
    # var selector_case = newNimNode(nnkCaseStmt)   
    # selector_case.add(newIdentNode("selector"))
    

    # Create main func / selector.
    let main_func = parseStmt(
        """
        proc main() {.exportwasm.} =
            if getCallDataSize() < 4:
                revert(nil, 0)           
        """
    )
    out_stmts.add(main_func)
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

    for f in function_signatures:
        echo f.method_id
        selector_CaseStmt.add(
            nnkOfBranch.newTree(  # of 0x<>'u32:
                parseExpr( "0x" & f.method_id & "'u32"),
                nnkStmtList.newTree(
                    nnkDiscardStmt.newTree(
                    newEmptyNode()
                    )
                )
            )
        )
    # Add default revert into selector.
    selector_CaseStmt.add(
        nnkElse.newTree(
            nnkStmtList.newTree(
            nnkCall.newTree(
                newIdentNode("revert"),
                newNilLit(),
                newLit(0)
            )
        )
      )
    )

    out_stmts.add(selector_CaseStmt)

    # echo out_stmts

    # build selector:
    # keccak256("balance(address):(uint64)")[0, 4]

    return out_stmts


macro contract*(contract_name: string, proc_def: untyped): untyped =
    echo contract_name
    # echo "Before:"
    echo treeRepr(proc_def)
    expectKind(proc_def, nnkStmtList)
    var stmtlist = handleContractInterface(proc_def)
    # echo "After:"
    # echo treeRepr(stmtlist)
    return stmtlist
