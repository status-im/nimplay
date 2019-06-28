import macros
import strutils

import ./types


proc raiseParserError*(msg: string, line_info: LineInfo) =
    var out_msg = "\n" & line_info.filename & "\n"
    var line_no = 1
    var file_str = staticRead(line_info.filename)
    for line in file_str.splitLines():
        if line_no == line_info.line:
            out_msg &= line & "\n"
            out_msg &= "-".repeat(line_info.column) & "^"
            break
        inc(line_no)
    raise newException(ParserError, out_msg)


proc raiseParserError*(msg: string, node: NimNode) =
    let line_info = lineInfoObj(node)
    raiseParserError(msg, line_info)
