import ../nimplay/nimplay_macros
import ../nimplay/types
import ../nimplay/ewasm_eei
import stint

# import nimplay0_1

contract("KingOfTheHill"):

  # Globals
  var
    king_name*: bytes32
    king_addr*: address
    king_value*: wei_value
    king_else*: uint128

  # Events
  # proc BecameKing(name: bytes32, value: uint128) {.event.}
  proc BecameKing2(name {.indexed.}: bytes32, value: uint128) {.event.}

  # Methods
  proc becomeKing*(name: bytes32) {.payable,self,msg,log.} =
    if msg.value > self.king_value:
      self.king_name = name
      self.king_addr = msg.sender
      self.king_value = msg.value
      # log.BecameKing(name, msg.value)
      log.BecameKing2(name, msg.value)

  # proc getKing*(): bytes32 {.self.} =
  #   self.king_name

  # proc getKingAddr*(): address {.self.} =
  #   self.king_addr

  # proc getKingValue*(): wei_value {.self.} =
  #   self.king_value
