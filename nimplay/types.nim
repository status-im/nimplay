import stint
import tables
import macros
import sequtils

# Nimplay types.

type
  uint256* = StUint[256]
  int128* = StInt[128]
  uint128* = StUint[128]
  address* = array[20, byte]
  bytes32* = array[32, byte]
  wei_value* = uint128

# Nimplay structs.

type
  VariableType* = object
    name*: string
    var_type*: string
    key_types*: seq[string]
    slot*: int64

type
  EventType* = object
    name*: string
    var_type*: string
    indexed*: bool
    param_position*: int

type
  FunctionSignature* = object
    name*: string
    inputs*: seq[VariableType]
    outputs*: seq[VariableType]
    constant*: bool
    payable*: bool
    method_id*: string
    method_sig*: string
    is_private*: bool
    line_info*: LineInfo
    pragma_base_keywords*: seq[string]  # list of pragmas

type
  EventSignature* = object
    name*: string
    inputs*: seq[EventType]
    outputs*: seq[EventType]
    definition*: NimNode

type
  LocalContext* = object
    # Name of the function.
    name*: string
    # Function signature, used for function selection and ABI encoding / decoding.
    sig*: FunctionSignature
    # Global temp variables create at beginning of the function.
    keyword_define_stmts*: NimNode
    # Map of temp variables that have to be replaced by.
    global_keyword_map*: Table[string, string]

type
  GlobalContext* = object
    global_variables*: Table[string, VariableType]
    events*: Table[string, EventSignature]
    getter_funcs*: seq[VariableType]
    has_default_func*: bool

# Exceptions.

type ParserError* = object of Exception

# Nimplay constants.

let
  KEYWORDS* {.compileTime.} = @["contract", "self", "log"]
  TYPE_NAMES* {.compileTime.} = @["address", "uint256", "bytes32", "int128", "uint128"]
  ALL_KEYWORDS* {.compileTime.} = concat(TYPE_NAMES, KEYWORDS)
  ALLOWED_PRAGMAS* {.compileTime.} = @["payable", "event", "self", "msg", "log"]

# Constants

let ZERO_ADDRESS*: address = [
  0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8,
  0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8
]
