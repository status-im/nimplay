import ../eth_contracts
import ../eth_macros

import macros
import stint


expandMacros:
  contract("MyContract"):

    func addition(a: uint256, b: uint256): uint256 =
      return a + b

    proc hello(): uint256 =
      return (123).stuint(256)

    proc hellonone() =
      discard

    proc addition(a: uint256, b: uint256): uint256 =
      return a + b


# contract("MyContract"):
#     lib: from("lib/...")

#     proc hello(): uint256 =
#       lib.sha500()
