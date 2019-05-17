import ../eth_contracts
import endians
import stint


# proc main() {.exportwasm.} =
#     proc test() =
#         return 1
#     var res = 1234.stuint(256).toByteArrayBE
#     finish(addr res, sizeof(res).int32)

proc main() {.exportwasm.} =
    proc test(): int =
        return 1
    var res = 1234.stuint(256).toByteArrayBE
    finish(addr res, sizeof(res).int32)
