import macros
import strutils
import stint
import nimcrypto/keccak
import nimcrypto/hash
import nimcrypto/utils
import osproc


type
    VariableType* = object
        name: string
        var_type: string


type
    FunctionSignature* = object
        name: string
        method_id: string
        inputs: seq[VariableType]
        outputs: seq[VariableType]
        constant: bool
        payable: bool


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


proc getKHash(inp: string): string =
    let exec_string = "tools/k256_sig \"" & inp & "\""
    echo exec_string
    let outp_shell = execProcess(exec_string)
    echo outp_shell
    return outp_shell


proc generate_method_id*(func_sig: FunctionSignature): uint32 =
    # var method_str = generate_method_sig(func_sig)
    # echo method_str
    # return keccak_256.digest(method_str).data
    return parseHexInt(getKHash(generate_method_sig(func_sig))[0..4])


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

    echo "method_id: " & generate_method_sig(func_sig)
    
    # var s = newSeq[byte]()
    # var method_hash = generate_method_id(func_sig)
    # for i in method_hash:
    #     s.add(i)
    # echo "method_hash" & toHex(method_hash)

    return func_sig
