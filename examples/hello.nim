import ../eth_contracts
import endians
import stint


proc main() {.exportwasm.} =
    var res = 1234.stuint(256).toByteArrayBE
    finish(addr res, sizeof(res).int32)
