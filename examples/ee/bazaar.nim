import system/alloc

import ../../nimplay/ee_runtime


proc main() {.exportwasm.} =
  var
    pre_state_root {.noinit.}: array[32, byte]
    post_state_root {.noinit.}: array[32, byte]

  eth2_loadPreStateRoot(addr pre_state_root)
  var
    block_data_size = eth2_blockDataSize()
    block_data = alloc(block_data_size)

  eth2_blockDataCopy(addr block_data, 0, block_data_size)
  eth2_savePostStateRoot(addr post_state_root)
