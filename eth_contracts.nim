import macros

{.pragma: importwasm, importc, cdecl.}

proc getCallDataSize*(): uint32 {.importwasm.}

macro exportwasm*(p: untyped): untyped =
  expectKind(p, nnkProcDef)
  result = p
  result.addPragma(newIdentNode("exportc"))
  result.addPragma(newColonExpr(newIdentNode("codegenDecl"), newLit("__attribute__ ((visibility (\"default\"))) $# $#$#")))
