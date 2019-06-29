import macros
import strutils
import tables
import re

import ./types


proc raiseParserError*(in_msg: string, line_info: LineInfo) =
    var out_msg = "\n\n" & line_info.filename & "\n"
    var line_no = 1
    var file_str = staticRead(line_info.filename)
    for line in file_str.splitLines():
        if line_no == line_info.line:
            out_msg &= line & "\n"
            out_msg &= "-".repeat(line_info.column) & "^\n"
            break
        inc(line_no)
    out_msg &= "PlayParserError: " & in_msg & "\n\n"
    raise newException(ParserError, out_msg)


proc raiseParserError*(msg: string, node: NimNode) =
    let line_info = lineInfoObj(node)
    raiseParserError(msg, line_info)


proc check_valid_variable_name*(node: NimNode, global_ctx: GlobalContext) =
    expectKind(node, nnkIdent)
    var name = strVal(node)
    var err_msg = ""

    if global_ctx.global_variables.hasKey(name):
        err_msg = "Variable name is same as a global variable, please chose another name."
    elif name in ALL_KEYWORDS:
        err_msg = "Variable name to similar to a keyword."

    # TODO:
    # elif not match(name, re"^[_a-zA-Z][a-zA-Z0-9_]*$"):
    #     # prevent homograph attack.
    #     err_msg = "Invalid variable name, only alphanumeric characters with underscore are supported."
  
    if err_msg != "":
        raiseParserError(err_msg, node)
