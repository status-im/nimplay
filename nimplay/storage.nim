import macros
import strformat
import strutils
import tables

import ./types


proc generate_storage_get_func*(storage_keword: string, global_ctx: GlobalContext): (NimNode, string) =
  var
    global_var_name = storage_keword.split(".")[1]
    new_proc_name = fmt"get_{global_var_name}_from_storage"
    var_info = global_ctx.global_variables[global_var_name]
    slot_number = var_info.slot

  if var_info.var_type == "uint256":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(): uint256 =
      var
        tmp: array[32, byte]
        pos = {$slot_number}.stuint(32).toByteArrayBE
      storageLoad(pos, addr tmp)
      return Uint256.fromBytesBE(tmp)
    """)
    return (new_proc, new_proc_name)
  elif var_info.var_type == "uint128" or var_info.var_type == "wei_value":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(): {var_info.var_type} =
      var
        tmp: array[32, byte]
        tmp_ba: array[16, byte]
        pos = {$slot_number}.stuint(32).toByteArrayBE
      storageLoad(pos, addr tmp)
      for i in 0..15:
        tmp_ba[i] = tmp[i]
      return Uint128.fromBytesBE(tmp_ba)
    """)
    return (new_proc, new_proc_name)
  elif var_info.var_type == "address":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(): address =
      var
        tmp: array[32, byte]
        pos = {$slot_number}.stuint(32).toByteArrayBE
      storageLoad(pos, addr tmp)
      var out_var: address 
      # out_var[0..19] = tmp[12..31]
      for i, b in tmp:
        if i >= 12:
          out_var[i - 12] = b
      return out_var
    """)
    return (new_proc, new_proc_name)
  elif var_info.var_type == "bytes32":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(): bytes32 =
      var 
        tmp: bytes32
        pos = {$slot_number}.stuint(32).toByteArrayBE
      storageLoad(pos, addr tmp)
      return tmp
    """)
    return (new_proc, new_proc_name)
  else:
    raise newException(ParserError, var_info.var_type & " storage is not supported at the moment.")


proc generate_storage_set_func*(storage_keyword: string, global_ctx: GlobalContext): (NimNode, string) =
  var
    global_var_name = storage_keyword.split(".")[1]
    new_proc_name = fmt"set_{global_var_name}_in_storage"
    var_info = global_ctx.global_variables[global_var_name]
    slot_number = var_info.slot

  if var_info.var_type == "uint256":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(value:uint256) =
      var
        tmp: array[32, byte] = value.toByteArrayBE
        pos = {$slot_number}.stuint(32).toByteArrayBE
      storageStore(pos, addr tmp)
    """)
    return (new_proc, new_proc_name)
  elif var_info.var_type == "uint128" or var_info.var_type == "wei_value":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(value: {var_info.var_type}) =
      var
        tmp: array[32, byte]
        pos = {$slot_number}.stuint(32).toByteArrayBE
        tmp_ba = value.toByteArrayBE
      for i in 0..15:
        tmp[i] = tmp_ba[i]
      storageStore(pos, addr tmp)
    """)
    return (new_proc, new_proc_name)
  elif var_info.var_type == "address":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(value: address) =
      var
        tmp: array[32, byte]
        pos = {$slot_number}.stuint(32).toByteArrayBE
      for i, b in value:
        tmp[12 + i] = b
      storageStore(pos, addr tmp)
    """)
    return (new_proc, new_proc_name)
  elif var_info.var_type == "bytes32":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(value: bytes32) =
      var pos = {$slot_number}.stuint(32).toByteArrayBE
      storageStore(pos, unsafeAddr value)
    """)
    return (new_proc, new_proc_name)
  else:
    raise newException(ParserError, var_info.var_type & " storage is not supported at the moment.")
