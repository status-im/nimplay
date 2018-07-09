import macros

{.push cdecl, importc.}

proc useGas*(amount: int64)
## Subtracts an amount to the gas counter
##
## Parameters:
##   `amount` - the amount to subtract to the gas counter

proc getAddress*(resultOffset: pointer)
## Gets address of currently executing account and loads it into memory at
## the given offset.
##
## Parameters:
##   `resultOffset` the memory offset to load the address into (`address`)

proc getBalance*(addressOffset, resultOffset: pointer)
## Gets balance of the given account and loads it into memory at the given offset.
##
## Parameters:
##   `addressOffset` the memory offset to load the address from (`address`)
#    `resultOffset` the memory offset to load the balance into (`u128`)

proc getBlockHash*(number: int64, resultOffset: pointer)
## Gets the hash of one of the 256 most recent complete blocks.
##
## Parameters:
##   `number` which block to load
##   `resultOffset` the memory offset to load the hash into (`u256`)

proc call*(gas: int64, addressOffset, valueOffset, dataOffset: pointer,
            dataLength: int32): int32
## Sends a message with arbitrary data to a given address path
##
## Parameters:
##   `gas` **i64** the gas limit
##   `addressOffset` the memory offset to load the address from (`address`)
##   `valueOffset` the memory offset to load the value from (`u128`)
##   `dataOffset` the memory offset to load data from (`bytes`)
##   `dataLength` the length of data
## Returns:
##   0 on success, 1 on failure and 2 on `revert`

proc callDataCopy*(resultOffset: pointer, dataOffset, length: int32)
## Copies the input data in current environment to memory. This pertains to
## the input data passed with the message call instruction or transaction.
##
## Parameters:
##   `resultOffset` the memory offset to load data into (`bytes`)
##   `dataOffset` the offset in the input data
##   `length` the length of data to copy

proc getCallDataSize*(): int32
## Get size of input data in current environment. This pertains to the input
## data passed with the message call instruction or transaction.
##
## Returns: call data size

proc callCode*(gas: int64, addressOffset, valueOffset, dataOffset: pointer,
                dataLength: int32): int32
## Message-call into this account with an alternative account's code.
##
## Parameters:
##   `gas` the gas limit
##   `addressOffset` the memory offset to load the address from (`address`)
##   `valueOffset` the memory offset to load the value from (`u128`)
##   `dataOffset` the memory offset to load data from (`bytes`)
##   `dataLength` the length of data
##
## Returns: 0 on success, 1 on failure and 2 on `revert`

proc callDelegate*(gas: int64, addressOffset, dataOffset: pointer,
                    dataLength: int32)
## Message-call into this account with an alternative account’s code, but
## persisting the current values for sender and value.
##
## Parameters:
##   `gas` the gas limit
##   `addressOffset` the memory offset to load the address from (`address`)
##   `dataOffset` the memory offset to load data from (`bytes`)
##   `dataLength` the length of data
##
## Returns: 0 on success, 1 on failure and 2 on `revert`

proc callStatic*(gas: int64, addressOffset, dataOffset: pointer,
                  dataLength: int32)
## Sends a message with arbitrary data to a given address path, but disallow
## state modifications. This includes `log`, `create`, `selfdestruct` and `call`
## with a non-zero value.
##
## Parameters:
##   `gas` the gas limit
##   `addressOffset` the memory offset to load the address from (`address`)
##   `dataOffset` the memory offset to load data from (`bytes`)
##   `dataLength` the length of data
##
## Returns: 0 on success, 1 on failure and 2 on `revert`

proc storageStore*(pathOffset, valueOffset: pointer)
## Store 256-bit a value in memory to persistent storage
##
## Parameters:
##   `pathOffset` the memory offset to load the path from (`u256`)
##   `valueOffset` the memory offset to load the value from (`u256`)

proc storageLoad*(pathOffset, valueOffset: pointer)
## Loads a 256-bit a value to memory from persistent storage
##
## Parameters:
##   `pathOffset` the memory offset to load the path from (`u256`)
##   `resultOffset` the memory offset to store the result at (`u256`)

proc getCaller*(resultOffset: pointer)
## Gets caller address and loads it into memory at the given offset. This is
## the address of the account that is directly responsible for this execution.
##
## Parameters:
##   `resultOffset` the memory offset to load the address into (`address`)

proc getCallValue*(resultOffset: pointer)
## Gets the deposited value by the instruction/transaction responsible for
## this execution and loads it into memory at the given location.
##
## Parameters:
##   `resultOffset` the memory offset to load the value into (`u128`)

proc codeCopy*(resultOffset: pointer, codeOffset, length: int32)
## Copies the code running in current environment to memory.
##
## Parameters:
##   `resultOffset` the memory offset to load the result into (`bytes`)
##   `codeOffset` the offset within the code
##   `length` the length of code to copy

proc getCodeSize*(): int32
## Gets the size of code running in current environment.

proc getBlockCoinbase*(resultOffset: pointer)
## Gets the block’s beneficiary address and loads into memory.
##
## Parameters:
##   `resultOffset` the memory offset to load the coinbase address into (`address`)

proc create*(valueOffset, dataOffset: pointer, length: int32, resultOffset: pointer): int32
## Creates a new contract with a given value.
##
## Parameters:
##   `valueOffset` the memory offset to load the value from (`u128`)
##   `dataOffset` the memory offset to load the code for the new contract from (`bytes`)
##   `length` the data length
##   `resultOffset` the memory offset to write the new contract address to (`address`)
##
## Note: `create` will clear the return buffer in case of success or may fill
##        it with data coming from `revert`.
##
## Returns: 0 on success, 1 on failure and 2 on `revert`

proc getBlockDifficulty*(resultOffset: pointer)
## Get the block’s difficulty.
##
## Parameters:
##   `resultOffset` the memory offset to load the difficulty into (`u256`)

proc externalCodeCopy*(addressOffset, resultOffset: pointer, codeOffset, length: int32)
## Copies the code of an account to memory.
##
## Parameters:
##   `addressOffset` the memory offset to load the address from (`address`)
##   `resultOffset` the memory offset to load the result into (`bytes`)
##   `codeOffset` the offset within the code
##   `length` the length of code to copy

proc getExternalCodeSize*(addressOffset: pointer): int32
## Get size of an account’s code.
##
## Parameters:
##   `addressOffset` the memory offset to load the address from (`address`)

proc getGasLeft*(): int64
## Returns the current gasCounter

proc getBlockGasLimit*(): int64
## Get the block’s gas limit.

proc getTxGasPrice*(valueOffset: pointer)
## Gets price of gas in current environment.
##
## Parameters:
##   `valueOffset` the memory offset to write the value to (`u128`)

proc log*(dataOffset: pointer, length, numberOfTopics: int32,
          topic1, topic2, topic3, topic4: pointer)
## Creates a new log in the current environment
##
## Parameters:
##   `dataOffset` the memory offset to load data from (`bytes`)
##   `length` the data length
##   `numberOfTopics` the number of topics following (0 to 4)
##   `topic1` the memory offset to load topic1 from (`u256`)
##   `topic2` the memory offset to load topic2 from (`u256`)
##   `topic3` the memory offset to load topic3 from (`u256`)
##   `topic4` the memory offset to load topic4 from (`u256`)

proc getBlockNumber*(): int64
## Get the block’s number.

proc getTxOrigin*(resultOffset: pointer)
## Gets the execution's origination address and loads it into memory at the
## given offset. This is the sender of original transaction; it is never an
## account with non-empty associated code.
##
## Parameters:
##   `resultOffset` the memory offset to load the origin address from (`address`)

proc ret*(dataOffset: pointer, length: int32) {.
            importc: "retAux", codegenDecl: "$# $#$# __asm__(\"return\")".}
## Set the returning output data for the execution.
##
## Note: multiple invocations will overwrite the previous data.
##
## Parameters:
##   `dataOffset` the memory offset of the output data (`bytes`)
##   `length` the length of the output data

proc revert*(dataOffset: pointer, length: int32)
## Set the returning output data for the execution.
##
## Note: multiple invocations will overwrite the previous data.
##
## Parameters:
##   `dataOffset` the memory offset of the output data (`bytes`)
##   `length` the length of the output data

proc getReturnDataSize*(): int32
## Get size of current return data buffer to memory. This contains the return
## data from the last executed `call`, `callCode`, `callDelegate`, `callStatic`
## or `create`.
##
## Note: `create` only fills the return data buffer in case of a failure.

proc returnDataCopy*(resultOffset: pointer, dataOffset, length: int32)
## Copies the current return data buffer to memory. This contains the return data
## from last executed `call`, `callCode`, `callDelegate`, `callStatic` or `create`.
##
## Note: `create` only fills the return data buffer in case of a failure.
##
## Parameters:
##   `resultOffset` the memory offset to load data into (`bytes`)
##   `dataOffset` the offset in the return data
##   `length` the length of data to copy

proc selfDestruct*(addressOffset: pointer)
## Mark account for later deletion and give the remaining balance to the specified
## beneficiary address. This takes effect once the contract execution terminates.
##
## Note: multiple invocations will overwrite the benficiary address.
##
## Note: the contract **shall** halt execution after this call.
##
## Parameters:
##   `addressOffset` the memory offset to load the address from (`address`)

proc getBlockTimestamp*(): int64
## Get the block’s timestamp.

{.pop.}

proc callDataCopy*[T](res: var T, offset: int) {.inline.} =
  callDataCopy(addr res, offset.int32, sizeof(res).int32)

proc storageLoad*[N](path: array[N, byte], res: pointer) {.inline.} =
  when path.len < 32:
    type PaddedPath {.packed.} = object
      padding: array[32 - path.len, byte]
      p: array[N, byte]
    var p: PaddedPath
    p.p = path
    storageLoad(addr p, res)
  else:
    storageLoad(unsafeAddr path[0], res)

proc storageStore*[N](path: array[N, byte], res: pointer) {.inline.} =
  when path.len < 32:
    type PaddedPath {.packed.} = object
      padding: array[32 - path.len, byte]
      p: array[N, byte]
    var p: PaddedPath
    p.p = path
    storageStore(addr p, res)
  else:
    storageStore(unsafeAddr path[0], res)

macro exportwasm*(p: untyped): untyped =
  expectKind(p, nnkProcDef)
  result = p
  result.addPragma(newIdentNode("exportc"))
  result.addPragma(newColonExpr(newIdentNode("codegenDecl"), newLit("__attribute__ ((visibility (\"default\"))) $# $#$#")))
