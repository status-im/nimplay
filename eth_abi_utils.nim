import macros
import strutils
import nimcrypto

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


proc generate_method_sig*(func_sig: FunctionSignature): string =
    var inputs: seq[string]
    for input in func_sig.inputs:
        inputs.add(input.var_type)
    var method_str = func_sig.name & "(" & join(inputs, ",") & ")"
    if len(func_sig.outputs) > 0:
        var outputs: seq[string]
        for output in func_sig.outputs:
            outputs.add(output.var_type)
        method_str = method_str & ":(" & join(outputs, ",") & ")"
    return method_str


proc generate_method_id*(func_sig: FunctionSignature): string =
    return keccak_256.digest(generate_method_sig(func_sig))


proc generate_function_signature*(proc_def: NimNode): FunctionSignature =

    var func_sig = FunctionSignature()
    for child in proc_def:
        case child.kind:
        of nnkIdent:
            func_sig.name = strVal(child)
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
    echo generate_method_id(func_sig)
    echo "%%%^^"

    return func_sig

