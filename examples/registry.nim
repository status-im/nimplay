import ../nimplay0_1


contract("Registry"):

  names: StorageTable[bytes32, bytes32]

  proc set_name*(k: bytes32, v: bytes32) {.self,msg.} =
    self.names[k] = v

  # proc get_name(k: bytes32) {.self.} =
  #   self.names[k]
