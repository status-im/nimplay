import ../../nimplay/substrate_runtime


# Init function.
proc deploy(): uint32 {.exportwasm.} =
  0

# Main function.
proc call(): uint32 {.exportwasm.} =
  var
    s = cstring("Hello world!")
  ext_println(s, s.len.int32)
  ext_scratch_write(s, s.len.int32)
  0 # return
