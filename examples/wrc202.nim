import ../eth_contracts
import ../eth_macros

import macros


const main_file_path = currentSourcePath()


proc MyContract() {.contract.} =
  proc hello(): int =
    return 1
