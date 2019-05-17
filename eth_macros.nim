import macros
# import json

type ParserError = object of Exception

#     {
#     "name": "test",
#     "outputs": [{
#         "type": "int32",
#         "name": "out"
#     }],
#     "inputs": [],
#     "constant": True,
#     "payable": False,
#     "type": "function",
# }


proc handleProcDef(func_stmt: NimNode): (string, NimNode) =
    var func_name = ""
    # for child in func_stmt:
    #     if child.kind == nnkIdent:
    #         func_name = strVal(child)
    return (func_name, func_stmt)


proc finalStmtList(stmts: NimNode): NimNode = 
    var out_stmts = newStmtList()
    var function_names = newSeq[string]()

    for child in stmts:
        case child.kind:
        of nnkProcDef:
            let (func_name, out_def) = handleProcDef(child)
            function_names.add(func_name)
            out_stmts.add(out_def)
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


macro contract*(proc_def: untyped): untyped =
    # echo "Before:"
    # echo treeRepr(proc_def)
    expectKind(proc_def, nnkProcDef)

    var final = newNimNode(nnkProcDef)
    var contract_name: string = ""
    var stmtlist = newStmtList()

    for child in proc_def:
        case child.kind:
        of nnkIdent:
            contract_name = strVal(child)
        of nnkStmtList:
            for s in finalStmtList(child):
                stmtlist.add(s)
        of nnkFormalParams:
            discard
        else:
            stmtlist.add(child)

    echo "After:"
    echo treeRepr(stmtlist)
    return stmtlist
