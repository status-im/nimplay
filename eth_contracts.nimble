version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "Ethereum smart contracts in Nim"
license       = "Apache License 2.0"
skipDirs      = @["examples"]

# Dependencies

requires "nim >= 0.18.1", "stint", "nimcrypto"

proc buildExample(name: string) =
  exec "nim c -d:release --out:examples/" & name & ".wasm examples/" & name
  exec "./postprocess.sh examples/" & name & ".wasm"


proc buildTool(name: string) =
  exec "nim c -d:release --out:tools/" & name & " tools/" & name


task examples, "Build examples":
  # buildExample("wrc20")
  buildExample("wrc202")
  # buildExample("hello")
  # buildExample("hello2")


task tools, "Build tools":
  buildTool("abi_gen")
  buildTool("k256_sig")
