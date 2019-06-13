import ../eth_contracts
import ../eth_macros

import macros
import stint


expandMacros:
  contract("MyContract"):
    
    proc hello(): uint256 =
      dumpAstGen:
        var selector: uint32
        callDataCopy(selector, 0)
        case selector
        of 0x9993021a'u32:
          discard
        else:
          revert(nil, 0)

      return (123).stuint(256)

    # func addition(a: uint256, b: uint256): uint256 =
    #   return a + b

    # proc hellonone() =
    #   discard

    # proc addition(a: uint256, b: uint256): uint256 =
    #   return a + b


# contract("MyContract"):
#     lib: from("lib/...")

#     proc hello(): uint256 =
#       lib.sha500()
