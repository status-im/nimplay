import ../eth_contracts

proc test(): int32 {.exportwasm.} =
  let sz = getCallDataSize().int32
