## ewasm “WRC20” token contract coding challenge
## https://gist.github.com/axic/16158c5c88fbc7b1d09dfa8c658bc363

import ../eth_contracts, endians

proc do_balance() =
  if getCallDataSize() != 24:
    revert(nil, 0)

  var address{.noinit.}: array[20, byte]
  callDataCopy(address, 4)

  var balance{.noinit.}: array[32, byte]
  storageLoad(address, addr balance)
  finish(addr balance, sizeof(balance).int32)

proc do_transfer() =
  if getCallDataSize() != 32:
    revert(nil, 0)

  var sender: array[20, byte]
  getCaller(addr sender)
  var recipient: array[20, byte]
  callDataCopy(recipient, 4)
  var value: array[8, byte]
  callDataCopy(value, 24)

  var senderBalance: array[32, byte]
  storageLoad(sender, addr senderBalance)
  var recipientBalance: array[32, byte]
  storageLoad(recipient, addr recipientBalance)

  var sb, rb, v: uint64

  bigEndian64(addr v, addr value)
  bigEndian64(addr sb, addr senderBalance[32 - 8])

  if sb < v:
    revert(nil, 0)

  bigEndian64(addr rb, addr recipientBalance[32 - 8])

  sb -= v
  rb += v # TODO there's an overflow possible here..

  bigEndian64(addr senderBalance[32 - 8], addr sb)
  bigEndian64(addr recipientBalance[32 - 8], addr rb)

  storageStore(sender, addr senderBalance)
  storageStore(recipient, addr recipientBalance)

proc main() {.exportwasm.} =
  if getCallDataSize() < 4:
    revert(nil, 0)
  var selector: uint32
  callDataCopy(selector, 0)
  case selector
  of 0x9993021a'u32:
    do_balance()
  of 0x5d359fbd'u32:
    do_transfer()
  else:
    revert(nil, 0)
