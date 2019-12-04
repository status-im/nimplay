import ../../nimplay/ee_runtime


proc main() {.exportwasm.} =
  var
    pre_state_root: array[32, byte] 
  eth2_loadPreStateRoot(addr pre_state_root)
  debug_log("hello world!")
  debug_print32(42)
  debug_print64(99'u64)

  var
    post_state_root = pre_state_root  # no changes
  eth2_savePostStateRoot(addr post_state_root)


# extern crate ewasm_api;

# use ewasm_api::*;

# #[cfg(not(test))]
# #[no_mangle]
# pub extern "C" fn main() {
#     let pre_state_root = eth2::load_pre_state_root();

#     // Show debug functionality
#     debug::log("hello world!");
#     debug::print32(42);
#     debug::print64(99);
#     debug::print_mem(&pre_state_root.bytes);
#     debug::print_mem_hex(&pre_state_root.bytes);

#     assert!(eth2::block_data_size() == 0);

#     // No updates were made to the state
#     let post_state_root = pre_state_root;

#     eth2::save_post_state_root(&post_state_root)
# }
