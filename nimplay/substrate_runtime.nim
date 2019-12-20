import macros

{.push cdecl, importc.}

proc ext_address*()
proc ext_block_number*()
proc ext_gas_left*()
proc ext_gas_price*()
proc ext_get_storage*(key_ptr: pointer): int32
proc ext_now*()
proc ext_println*(str_ptr: pointer, str_len: int32) # experimental; will be removed.
proc ext_random_seed*()
proc ext_scratch_read*(dest_ptr: pointer, offset: int32, len: int32)
proc ext_scratch_size*(): int32
proc ext_scratch_write*(src_ptr: pointer, len: int32)
proc ext_set_rent_allowance*(value_ptr: pointer, value_len: int32)
proc ext_set_storage*(key_ptr: pointer, value_non_null: int32, value_ptr: int32, value_len: int32)
proc ext_value_transferred*()

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
