import ../eth_contracts
import endians
import stint


# proc main() {.exportwasm.} =
#     proc test() =
#         return 1
#     var res = 1234.stuint(256).toByteArrayBE
#     finish(addr res, sizeof(res).int32)

proc main() {.exportwasm.} =
    var selector: uint32
    callDataCopy(selector, 0)
    bigEndian32(addr selector, addr selector)
    case selector
    of 0xb0f0c96a'u32:
        var a: uint32 = 33333
        finish(addr a, sizeof(a).int32)
    else:
        finish(addr selector, sizeof(selector).int32)

    # var hello_param_0: array[32, byte]
    # callDataCopy(addr hello_param_0, 0, 32)
    # finish(addr hello_param_0, 32)
    # proc test(): int =
    #     return 1
    # var res = 1234.stuint(256).toByteArrayBE
    # finish(addr res, sizeof(res).int32)
