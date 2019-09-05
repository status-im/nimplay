import ../nimplay0_1


contract("MapStorage"):

  proc test*() {.msg.} =
    var 
      tmp_in: array[5, byte] = [0x68'u8, 0x65'u8, 0x6c'u8, 0x6c'u8, 0x6f'u8]  # hello
      key: bytes32
      val: array[32, byte]
      sha256_address: array[20, byte]
    sha256_address[19] = 2'u8
    var res = call(
      20000.int64, # gas
      addr sha256_address,  # addressOffset (ptr)
      nil,  # valueOffset (ptr)
      addr tmp_in, # dataOffset (ptr)
      tmp_in.len.int32, # dataLength
    )
    if res == 1:  # call failed
      var i = 911.int32
      revert(addr i, 32)
    returnDataCopy(addr key, 0.int32, getReturnDataSize())
    val[29] = 1
    val[30] = 1
    val[31] = 1
    storageStore(addr key, addr val)

# tx = contract_.functions.test().buildTransaction({'from': acct.address, 'nonce': w3.eth.getTransactionCount(acct.address)})
# signed = acct.signTransaction(tx)
# tx_hash = w3.eth.sendRawTransaction(signed.rawTransaction)
# receipt = w3.eth.waitForTransactionReceipt(tx_hash)
