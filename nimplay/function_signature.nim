import macros
import strutils
import stint

import ./utils, ./types


proc generate_method_sig*(func_sig: FunctionSignature, v2_sig: bool = false): string =
    var inputs: seq[string]
    for input in func_sig.inputs:
        inputs.add(input.var_type)
    var method_str = func_sig.name & "(" & join(inputs, ",") & ")"
    if v2_sig and len(func_sig.outputs) > 0:
        var outputs: seq[string]
        for output in func_sig.outputs:
            outputs.add(output.var_type)
        method_str = method_str & ":(" & join(outputs, ",") & ")"
    return method_str


proc getKHash(inp: string): string {.compileTime.} =
    let exec_string = "../tools/k256_sig \"" & inp & "\""
    let outp_shell = staticExec(exec_string)
    return outp_shell


proc generate_method_id*(func_sig: FunctionSignature): string =
    # var method_str = generate_method_sig(func_sig)
    # echo method_str
    # return keccak_256.digest(method_str).data
    return getKHash(generate_method_sig(func_sig))[0..7]


proc generate_function_signature*(proc_def: NimNode, global_ctx: GlobalContext): FunctionSignature =
    expectKind(proc_def, nnkProcDef)

    var func_sig = FunctionSignature()
    for child in proc_def:
        case child.kind:
        of nnkIdent:
            func_sig.name = strVal(child)
            func_sig.is_private = true
        of nnkPostfix:
            func_sig.name = strVal(child[1])
            func_sig.is_private = false
        of nnkFormalParams:
            for param in  child:
                case param.kind 
                of nnkIdent:
                    func_sig.outputs.add(
                        VariableType(
                            name: "out1",
                            var_type: strVal(param)
                        )
                    )
                of nnkIdentDefs:
                    check_valid_variable_name(param[0], global_ctx)
                    func_sig.inputs.add(
                        VariableType(
                            name: strVal(param[0]),
                            var_type: strVal(param[1])
                        )
                    )
                of nnkEmpty:
                    discard
                else:
                    raise newException(Exception, "unknown param type" & treeRepr(child))
        else:
            discard
            # raise newException(Exception, "unknown func type" & treeRepr(child))

    func_sig.method_sig = generate_method_sig(func_sig)
    func_sig.method_id = generate_method_id(func_sig)
    func_sig.line_info = lineInfoObj(proc_def)

    return func_sig
