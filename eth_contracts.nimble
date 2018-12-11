version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "Ethereum smart contracts in Nim"
license       = "Apache License 2.0"
skipDirs      = @["examples"]

# Dependencies

requires "nim >= 0.18.1", "stint"

proc buildExample(name: string) =
  exec "nim c -d:release --out:examples/" & name & ".wasm examples/" & name
  exec "./postprocess.sh examples/" & name & ".wasm"

task examples, "Build examples":
  buildExample("wrc20")
