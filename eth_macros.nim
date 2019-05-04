import macros


type ParserError = object of Exception


proc handleProcDef(func_stmt: NimNode): NimNode =
    return func_stmt


proc finalStmtList(stmts: NimNode): NimNode = 
    var out_stmts = newStmtList()
    for child in stmts:
        case child.kind:
        of nnkProcDef:
            out_stmts.add(handleProcDef(child))
        else:
            raise newException(ParserError, "Invalid stmt \"" & treeRepr(child) & "\" not supported in contract block")
    # Create main func / selector.
    let main_func = parseStmt(
    """
proc main() {.exportwasm.} =
    if getCallDataSize() < 4:
        revert(nil, 0)
    var selector: uint32
    callDataCopy(selector, 0)
    """
    )
    out_stmts.add(main_func)
    return out_stmts


macro contract_me*(contract_block: untyped): untyped =
    expectKind(contract_block, nnkStmtList)
    let final = finalStmtList(contract_block)
    echo "Before:"
    echo treeRepr(contract_block)
    echo "After:"
    echo treeRepr(final)
    return final
