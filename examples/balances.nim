import ../nimplay0_1


contract("Depository"):

  balances: StorageTable[address, bytes32, wei_value]

  proc deposit*(k: bytes32) {.self,msg,payable.} =
    self.balances[msg.sender][k] = msg.value

  proc get_balance*(k: bytes32): wei_value {.self,msg.} =
    self.balances[msg.sender][k]

#   proc withdraw*(amount: wei_value) =
#     var
#       balance = self.balances[msg.sender][k]

#     if amount <= balance:
#       self.balances[msg.sender][k] = 
#       call(
#         getGasLeft(),
#         addr msg.sender
#         amount,
#       )


# proc call*(gas: int64, addressOffset, valueOffset, dataOffset: pointer,
#             dataLength: int32, resultOffset: pointer,
#             resultLength: int32): int32
