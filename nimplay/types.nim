import stint
import tables
import macros
import sequtils

# Nimplay types.

type uint256* = StUint[256]
type int128* = StInt[128]
type address* = array[20, byte]
type bytes32* = array[32, byte]

# Nimplay structs.

type
    VariableType* = object
        name*: string
        var_type*: string
        slot*: int64

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

# Exceptions.

type ParserError* = object of Exception

# Nimplay constants.

let
    KEYWORDS* {.compileTime.} = @["contract", "self"]
    TYPE_NAMES* {.compileTime.} = @["address", "uint256", "bytes32"]
    ALL_KEYWORDS* {.compileTime.} = concat(TYPE_NAMES, KEYWORDS)
