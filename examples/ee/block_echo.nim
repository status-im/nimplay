import ../../nimplay/ee_runtime

{.compile: "malloc.c".}
proc malloc(n: int): pointer {.importc.}


proc copy_into_ba(to_ba: var auto, offset: int, from_ba: auto) =
  for i, x in from_ba:
    if offset + i > sizeof(to_ba) - 1:
      break
    to_ba[offset + i] = x


proc main() {.exportwasm.} =
  var
    pre_state_root {.noinit.}: array[32, byte]
    post_state_root {.noinit.}: array[32, byte]
  eth2_loadPreStateRoot(addr pre_state_root)
  var
    block_data_size = eth2_blockDataSize()
    block_data = malloc(block_data_size.int)
  eth2_blockDataCopy(block_data, 0, block_data_size)
  copyMem(addr post_state_root, block_data, 32)
  eth2_savePostStateRoot(addr post_state_root[0])
