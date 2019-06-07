import compiler / [ast, vmdef, vm, nimeval, options, parser, idents, condsyms,
                   nimconf, extccomp, astalgo, llstream, pathutils]
import json
import os

# proc get_abi_json*(function_sigs: seq[FunctionSignature]): string =
#     let jsonObject = %* {"element": "Hydrogen"}
#     return $jsonObject

type
    VariableType* = object
        name: string
        var_type: string


type
    FunctionSignature* = object
        name: string
        inputs: seq[VariableType]
        outputs: seq[VariableType]
        constant: bool
        payable: bool


proc string_to_ast*(s: string): PNode {.raises: [Exception] .} =
    var conf = newConfigRef()
    var cache = newIdentCache()
    condsyms.initDefines(conf.symbols)
    conf.projectName = "stdinfile"
    conf.projectFull = "stdinfile".AbsoluteFile
    conf.projectPath = canonicalizePath(conf, getCurrentDir().AbsoluteFile).AbsoluteDir
    conf.projectIsStdin = true
    loadConfigs(DefaultConfig, cache, conf)
    extccomp.initVars(conf)
    var node = parseString(s, cache, conf)
    if len(node.sons) > 1:
        result = node
    else:
        result = node.sons[0]


proc generate_function_signature(proc_def: PNode): FunctionSignature =
    doAssert(proc_def.kind == nkFuncDef)
    var func_sig = FunctionSignature()

    for child in proc_def.sons:
        case child.kind:
        of nkIdent:
            func_sig.name = child.ident.s
        of nkFormalParams:
            for param in  child:
                case param.kind
                of nkIdent:
                    func_sig.outputs.add(
                        VariableType(
                            name: "out1",
                            var_type: param.ident.s
                        )
                    )
                of nkIdentDefs:
                    func_sig.inputs.add(
                        VariableType(
                            name: param.sons[0].ident.s,
                            var_type: param.sons[1].ident.s
                        )
                    )
                of nkEmpty:
                    discard
                else:
                    raise newException(Exception, "unknown param type")
        else:
            discard
    return func_sig


proc getPublicFunctions(stmts: PNode): seq[FunctionSignature] =
    var public_functions: seq[FunctionSignature]
    for child in stmts:
        if child.kind == nkCall and len(child.sons) > 2:
            var first_son = child.sons[0]
            if first_son.kind == nkIdent and first_son.ident.s == "contract":
                var main_block = child
                for b in main_block.sons:
                    if b.kind == nkStmtList:
                        for s in b.sons:
                            if s.kind == nkFuncDef:
                                public_functions.add(
                                    generate_function_signature(s)
                                )
    return public_functions


proc generateJSONABI(funcs: seq[FunctionSignature]): string =
    var jsonObject = %* funcs
    return $jsonObject


proc main() =
    if paramCount() != 1:
        echo("Requires .nim file with contract() block macro")
        quit()
    if not existsFile(commandLineParams()[0]):
        echo("Requires .nim file with contract() block macro")
        quit()

    var nimFile = commandLineParams()[0]
    let node = string_to_ast(readFile(nimFile))

    if node.kind == nkStmtList:
        echo(generateJSONABI(getPublicFunctions(node)))
    else:
        raise newException(Exception, "Expected nkStmtList")


when is_main_module:
    main()
