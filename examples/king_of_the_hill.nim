import ../nimplay/nimplay_macros
import ../nimplay/types
import ../nimplay/ewasm_eei
import stint


contract("KingOfTheHill"):

    # Globals
    var
        king_name: bytes32
        king_addr: address
        king_value: wei_value
        king_else: uint128
    
    proc KingEvent(id {.topic.}: uint256, name: bytes32, value: uint128) {.event.}

    proc Transferred(_from: address, value: uint128) {.event.}

    proc becomeKing*(name: bytes32) {.self,msg,payable,log.} =

        # proc log__KingEvent(name: bytes32, value: uint128):
        #     ...
        #     ...
        #     ...

        if msg.value > self.king_value:
            self.king_name = name
            self.king_addr = msg.sender
            self.king_value = msg.value
            # transfer funds.
            # Transfer()
            log.KingEvent()

    proc getKing*(): bytes32 = 
        self.king_name

    proc getKingAddr*(): address = 
        self.king_addr

    proc getKingValue*(one: uint256): uint128 = 
        if true:
            self.king_value
        else:
            self.king_value
