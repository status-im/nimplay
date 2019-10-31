import 
  macros, strformat, strutils,
  tables, math

import
  ./types


proc raiseParserError*(in_msg: string, line_info: LineInfo) =
  var out_msg = "\n\n" & line_info.filename & "\n"
  var line_no = 1
  var line_no_prefix = $line_no & ":"
  var file_str = staticRead(line_info.filename)
  for line in file_str.splitLines():
    if line_no == line_info.line:
      line_no_prefix = $line_no & ":"
      out_msg &= line_no_prefix
      out_msg &=  line & "\n"
      out_msg &= "-".repeat(line_info.column + line_no_prefix.len) & "^\n"
      break
    inc(line_no)
  out_msg &= "PlayParserError: " & in_msg & "\n\n"
  raise newException(ParserError, out_msg)


proc raiseParserError*(msg: string, node: NimNode) =
  let line_info = lineInfoObj(node)
  raiseParserError(msg, line_info)


proc valid_var_chars(var_name: string): bool =
  var res = false
  for c in var_name:
    if c in {'a'..'z'}:
      res = true
    elif c in {'A'..'Z'}:
      res = true
    elif c == '_':
      res = true
    elif c in {'0'..'9'}:
      res = true
    else:
      res = false
      break
  return res


proc check_valid_variable_name*(node: NimNode, global_ctx: GlobalContext) =
  expectKind(node, nnkIdent)
  var
    name = strVal(node)
    err_msg = ""

  if global_ctx.global_variables.hasKey(name):
    err_msg = "Variable name is same as a global variable, please chose another name."
  elif name in ALL_KEYWORDS:
    err_msg = "Variable name to similar to a keyword."
  elif not valid_var_chars(name): # prevent homograph attack.
    err_msg = "Invalid variable name, only alphanumeric characters with underscore are supported."
  if err_msg != "":
    raiseParserError(err_msg, node)


proc get_byte_size_of*(type_str: string): int =
  let BASE32_TYPES_NAMES: array = [
    "bool",
    "uint256",
    "uint128",
    "int128",
    "address",
    "bytes32",
    "wei_value"
  ]
  if type_str in BASE32_TYPES_NAMES:
    return 32
  else:
    raise newException(ParserError, fmt"Unknown '{type_str}' type supplied!")


proc get_memory_byte_size_of*(type_str: string): int =
  if type_str in @["uint256", "bytes32"]:
    return 32
  elif type_str in @["address"]:
    return 20
  elif type_str in @["uint128", "int128", "wei_value"]:
    return 16
  else:
    raise newException(ParserError, fmt"Unknown '{type_str}' type supplied!")


func get_bit_size_of*(type_str: string): int =
  get_byte_size_of(type_str) * 8


proc hexstr_tointarray*[N: static[int]](in_str: string): array[N, int]=
  var out_arr: array[N, int]
  for i in countup(0, in_str.len - 2, 2):
    out_arr[floorDiv(i, 2)] = fromHex[int](in_str[i..i+1])
  out_arr
