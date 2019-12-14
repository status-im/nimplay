import utils

{.push cdecl, importc.}

proc ext_block_number*()
proc ext_get_storage*(key_ptr: pointer): int32
proc ext_println*(str_ptr: pointer, str_len: int32)
proc ext_scratch_read*(dest_ptr: pointer, offset: int32, len: int32)
proc ext_scratch_size*(): int32
proc ext_scratch_write(src_ptr: pointer, len: int32)
proc ext_set_rent_allowance*(value_ptr: pointer, value_len: int32)
proc ext_set_storage*(key_ptr: pointer, value_non_null: int32, value_ptr: int32, value_len: int32)

{.pop.}

macro exportwasm*(p: untyped): untyped =
  expectKind(p, nnkProcDef)
  result = p
  result.addPragma(newIdentNode("exportc"))
  result.addPragma(
    newColonExpr(
      newIdentNode("codegenDecl"), newLit("__attribute__ ((visibility (\"default\"))) $# $#$#")
    )
  )
