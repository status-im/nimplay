import ../nimplay0_1

# proc concat[I1, I2: static[int]; T](a: array[I1, T], b: array[I2, T]): array[I1 + I2, T] =
#   result[0..a.high] = a
#   result[a.len..result.high] = b

# proc exit_message(s: string) =
#   revert(cstring(s), s.len.int32)

# # balances: StorageTable[address, wei_value]
# proc setTableValue[N](table_id: int32, key: array[N, byte], value: var bytes32) {.inline.} =
#   type CombinedKey {.packed.} = object
#     table_id: int32
#     key: array[N, byte]

#   var
#     sha256_address: array[20, byte]
#     combined_key: CombinedKey
#     hashed_key: bytes32

#   sha256_address[19] = 2'u8
#   combined_key.table_id = table_id
#   combined_key.key = key

#   var res = call(
#     getGasLeft(), # gas
#     addr sha256_address,  # addressOffset (ptr)
#     nil,  # valueOffset (ptr)
#     addr combined_key, # dataOffset (ptr)
#     sizeof(combined_key).int32, # dataLength
#   )
#   if res == 1:  # call failed
#     exit_message("Could not call sha256 in setTableValue")
#     # raise newException(Exception, "Could not call sha256 in setTableValue")
#   if getReturnDataSize() != 32.int32:
#       exit_message("Could not call sha256, Incorrect return size")

#   returnDataCopy(addr hashed_key, 0.int32, 32.int32)
#   storageStore(hashed_key, addr value)


contract("MapStorage"):

  proc test*()  =
    var
      key: array[5, byte] = [0x68'u8, 0x65'u8, 0x6c'u8, 0x6c'u8, 0x6f'u8]

      val: bytes32
    val[31] = 0x75'u8
    setTableValue(0.int32, key, val)

# tx = contract_.functions.test().buildTransaction({'from': acct.address, 'nonce': w3.eth.getTransactionCount(acct.address)})
# signed = acct.signTransaction(tx)
# tx_hash = w3.eth.sendRawTransaction(signed.rawTransaction)
# receipt = w3.eth.waitForTransactionReceipt(tx_hash)


# tx = contract_.functions.set_name(b"key", b"value").buildTransaction({'from': acct.address, 'nonce': w3.eth.getTransactionCount(acct.address)})
