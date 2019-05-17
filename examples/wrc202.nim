import ../eth_contracts
import ../eth_macros

import macros

expandMacros:
  proc MyContract {.contract.} =

    proc hello(): int =
      result = 123

    proc helloone(): int =
      result = 1
