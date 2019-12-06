import ../../nimplay/ee_runtime


proc main() {.exportwasm.} =
  var
    pre_state_root {.noinit.}: array[32, byte]
    post_state_root {.noinit.}: array[32, byte]
  eth2_loadPreStateRoot(addr pre_state_root)
  debug_log("hello world!")
  debug_print32(42)
  debug_print64(99'u64)

  post_state_root = pre_state_root  # no changes
  post_state_root[30] = 0x11'u8
  post_state_Root[31] = 0x22'u8
  eth2_savePostStateRoot(addr post_state_root)
