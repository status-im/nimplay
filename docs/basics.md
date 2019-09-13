# Contract Interface

To setup a simple contract one makes use of the `contract` block macro.

```nim
contract("ContractName"):

    proc addition*(a: uint256, b: uint256): string =
        return a + b

```

The string paramater given to the `contract` block macro can be any unique string.

# Function Visibility

All nimplay functions need to be annotated as either private or public, all functions marked with
and asterisk `*` are public and can be called from a transaction or another contract.
If a contract is not marked as public, it will be unreachable from outside the contract.

# Payable

To mark a function open to receive funds, the `payable` function pragma is used.

```nim
contract("Main"):

  proc pay_me() {.payable.}: uint256 =
    1.stuint(256)
```

# Types

Type Name | Nim Type      | Runtime Size (B) | ABIv1 Size (B)
----------|-------------  |------------------|---------------
uint256   | StUint(256)   | 32               | 32
uint128   | StUint(128)   | 16               | 32
address   | array[20,byte]| 20               | 32
bytes32   | array[32,byte | 32               | 32


# Builtin Variables

To easily access the current transactions state as well block specific states the following builtin variables are exposed.

Variable Name | Type               | Contents
--------------|---------           |----------
msg.sender    | address            | Current address making CALL to contract
msg.value     | wei_value (uint128)| Ether value in wei


# Logging

To let the world know an event occured from a contract, Ethereum uses events. In Nimplay this can 
be achieved using the `{.event.}` with function without a body of code.
To emit an event the `log` base keyword is used.

```nim
contract("Main"):
    # Events
    proc nameGiven(name: bytes32, address: uint128) {.event.}

    proc setName*(name: bytes32):
        self.name = name
        log.nameGiven(name, msg.sender)
```

To indicate what parameters have to be indexed, for easy retrieval later use `{.indexed.}`, a maximum of 3 indexed topics (or parameters) are allowed.

```nim
contract("Main"):
    # Events
    proc nameGiven(name: bytes32, address {.indexed.}: uint128) {.event.}

```

# Mappings

Nimplay uses `StorageTable` type to indicated a mapping.

```nim
contract("Registry"):

  names: StorageTable[bytes32, bytes32]

  proc set_name*(k: bytes32, v: bytes32) {.self.} =
    self.names[k] = v

  proc get_name*(k: bytes32): bytes32 {.self.} =
    self.names[k]
```
