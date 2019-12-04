import macros

{.push cdecl, importc.}
proc eth2_loadPreStateRoot*(memoryOffset: pointer)
proc eth2_blockDataSize*(): uint32
proc eth2_blockDataCopy*(outputOfset: pointer, offset: uint32, length: uint32)
proc eth2_savePostStateRoot*(memoryOffset: pointer)
proc eth2_pushNewDeposit*(memoryOffset: pointer, length: uint32)
proc debug_print32*(value: uint32)
proc debug_print64*(value: uint64)
proc debug_printMem*(offset: pointer, length: uint32)
proc debug_printMemHex*(offset: pointer, length: uint32)
proc debug_printStorage*(pathOffset: pointer)
proc debug_printStorageHex*(pathOffset: pointer)

{.pop.}


proc debug_log*(s: string) =
    debug_printMem(cstring(s), s.len.uint32) 


macro exportwasm*(p: untyped): untyped =
  expectKind(p, nnkProcDef)
  result = p
  result.addPragma(newIdentNode("exportc"))
  result.addPragma(
    newColonExpr(
      newIdentNode("codegenDecl"), newLit("__attribute__ ((visibility (\"default\"))) $# $#$#")
    )
  )


# eth2::loadPreStateRoot(memoryOffset: u32ptr)
# The current pre_state_root (256-bit value) is loaded from the memory offset pointed at
# eth2::blockDataSize() -> u32
# Returns the size of the block.data
# eth2::blockDataCopy(memoryOffset: u32ptr, offset: u32, length: u32)
# Copies length bytes from block.data + offset to the memory offset
# eth2::savePostStateRoot(memoryOffset: u32ptr)
# The post_state_root (256-bit value) is set to the content of the memory offset pointed at
# eth2::pushNewDeposit(memoryOffset: u32ptr, length: u32)
# This expects a Deposit 2 data structure to be stored at the memory offset (SSZ serialised?). It will be appended to the deposit list.

# (type (;0;) (func (param i32)))
# (type (;1;) (func (param i32 i32)))
# (type (;2;) (func (param i64)))
# (type (;3;) (func (result i32)))
# (type (;4;) (func))
# (type (;5;) (func (param i32 i32 i32) (result i32)))
# (import "env" "eth2_loadPreStateRoot" (func $eth2_loadPreStateRoot (type 0)))
# (import "env" "debug_printMem" (func $debug_printMem (type 1)))
# (import "env" "debug_print32" (func $debug_print32 (type 0)))
# (import "env" "debug_print64" (func $debug_print64 (type 2)))
# (import "env" "debug_printMemHex" (func $debug_printMemHex (type 1)))
# (import "env" "eth2_blockDataSize" (func $eth2_blockDataSize (type 3)))
# (import "env" "eth2_pushNewDeposit" (func $eth2_pushNewDeposit (type 1)))
# (import "env" "eth2_savePostStateRoot" (func $eth2_savePostStateRoot (type 0)))

# pub fn eth2_loadPreStateRoot(offset: *const u32);
# pub fn eth2_blockDataSize() -> u32;
# pub fn eth2_blockDataCopy(outputOfset: *const u32, offset: u32, length: u32);
# pub fn eth2_savePostStateRoot(offset: *const u32);
# pub fn eth2_pushNewDeposit(offset: *const u32, length: u32);

# pub fn debug_print32(value: u32);
# pub fn debug_print64(value: u64);
# pub fn debug_printMem(offset: *const u32, len: uint32)
# pub fn debug_printMemHex(offset: *const u32, len: u32);
# pub fn debug_printStorage(pathOffset: *const u32);
# pub fn debug_printStorageHex(pathOffset: *const u32);
