import ../../nimplay/substrate_runtime

{.compile: "malloc.c".}
proc malloc(n: int): pointer {.importc.}

type 
  Action = enum
    Set = 0'u8, Get = 1'u8, SelfEvict = 2'u8

# Init function.
proc deploy(): uint32 {.exportwasm.} =
  0

proc get_scratch(): (pointer, int32) =
  var
    scratch_size = ext_scratch_size()
    mem_ptr = malloc(scratch_size.int)
  ext_scratch_read(mem_ptr, 0, scratch_size)
  (mem_ptr, scratch_size)

proc print(s: cstring) =
  ext_println(s, s.len.int32)


proc incr_pointer(oldp: pointer): pointer = 
  var newp = cast[pointer](cast[uint](oldp) + 1u)
  newp


proc set_val_in_store(scratch_ptr: pointer, scratch_size: int32) =
  print("Set".cstring)
  var
    key: array[32, byte] = [
      2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8,
      2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8,
      2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8, 2'u8,
      2'u8, 2'u8, 2'u8, 2'u8, 2'u8
    ]
    offset_ptr = incr_pointer(scratch_ptr)

  ext_set_storage(addr key, 1.int32 , offset_ptr, scratch_size - 1)

# Main function.
proc call(): uint32 {.exportwasm.} =
  var
    selector: uint8
    (scratch_ptr, scratch_size) = get_scratch()

  copyMem(addr selector, scratch_ptr, 1)

  case selector
  of Action.Set.ord:
    set_val_in_store(scratch_ptr, scratch_size)
  of Action.Get.ord:
    print("Get: Todo".cstring)
  of Action.SelfEvict.ord:
    print("SelfEvict: Todo".cstring)
  else:
    print("Unknown action passed".cstring)

  0 # return

# sys::ext_set_storage(
#     key.as_ptr() as u32,
#     1,
#     value.as_ptr() as u32,
#     value.len() as u32,
# )


# block_data = malloc(block_data_size.int)
# eth2_blockDataCopy(block_data, 0, block_data_size)
# copyMem(addr post_state_root, block_data, 32)
