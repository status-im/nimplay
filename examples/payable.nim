import ../nimplay/nimplay_macros
import ../nimplay/types
import ../nimplay/ewasm_eei
import stint


contract("PayAssert"):
   
  proc plus_two*(a: uint256): uint256 {.payable.} =
    a + 2

  proc plus_one*(a: uint256): uint256 =
    a + 1
