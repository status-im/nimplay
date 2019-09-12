import macros
import strformat
import strutils
import tables

import ./types, ./utils


proc generate_storage_get_func*(storage_keyword: string, global_ctx: GlobalContext): (NimNode, string) =
  var
    global_var_name = storage_keyword.split(".")[1]
    new_proc_name = fmt"get_{global_var_name}_from_storage"
    var_info = global_ctx.global_variables[global_var_name]
    slot_number = var_info.slot

  if var_info.var_type == "uint256":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(): uint256 =
      var
        tmp {{.noinit.}}: array[32, byte]
        pos = {$slot_number}.stuint(32).toByteArrayBE
      storageLoad(pos, addr tmp)
      return Uint256.fromBytesBE(tmp)
    """)
    return (new_proc, new_proc_name)
  elif var_info.var_type == "uint128" or var_info.var_type == "wei_value":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(): {var_info.var_type} =
      var
        tmp {{.noinit.}}: array[32, byte]
        tmp_ba {{.noinit.}}: array[16, byte]
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
        tmp {{.noinit.}}: array[32, byte]
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
        tmp {{.noinit.}}: bytes32
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
        tmp {{.noinit.}}: array[32, byte] = value.toByteArrayBE
        pos = {$slot_number}.stuint(32).toByteArrayBE
      storageStore(pos, addr tmp)
    """)
    return (new_proc, new_proc_name)
  elif var_info.var_type == "uint128" or var_info.var_type == "wei_value":
    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(value: {var_info.var_type}) =
      var
        tmp {{.noinit.}}: array[32, byte]
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
        tmp {{.noinit.}}: array[32, byte]
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


proc get_combined_key_info(var_info: VariableType): (string, seq[string], string, int) =
  var
    value_conversion = ""
    key_param_arr: seq[string]
    key_copy_block: string
    total_key_size = 0
    key_count = 0

  for key_type in var_info.key_types[0..^2]:
    var current_key_name = fmt"key{key_count}"
    key_param_arr.add(
      fmt"{current_key_name}: " & key_type
    )
    key_copy_block.add(
      fmt"      copy_into_ba(combined_key, {total_key_size}, {current_key_name})" & '\n'
    )
    inc(key_count)
    total_key_size += get_memory_byte_size_of(key_type)

  (value_conversion, key_param_arr, key_copy_block, total_key_size)


proc generate_storage_table_set_func*(storage_keyword: string, global_ctx: GlobalContext): (NimNode, string) =
  var
    global_var_name = storage_keyword.split(".")[1]
    var_info = global_ctx.global_variables[global_var_name]
    new_proc_name = fmt"set_{global_var_name}_in_storage_table"
    value_type = var_info.key_types[^1]
    table_id = var_info.slot
    (value_conversion, key_param_arr, key_copy_block, total_key_size) = get_combined_key_info(var_info)

  if value_type == "bytes32":
    value_conversion = "val"
  elif value_type in @["wei_value", "uint128"]:
    value_conversion = "val.to_bytes32"
  else:
    raise newException(ParserError, "Unsupported '{value_type}' value type.")

  var s = fmt"""
    proc {new_proc_name}({key_param_arr.join(",")}, val: {value_type}) =
      var
        tmp_val = {value_conversion}
        combined_key {{.noinit.}}: array[{total_key_size}, byte]
{key_copy_block}
      setTableValue({table_id}.int32, combined_key, tmp_val)
    """
  echo s
  var new_proc = parseStmt(s)
  return (new_proc, new_proc_name)


proc generate_storage_table_get_func*(storage_keyword: string, global_ctx: GlobalContext): (NimNode, string) =
  var
    global_var_name = storage_keyword.split(".")[1]
    new_proc_name = fmt"get_{global_var_name}_in_storage_table"
    var_info = global_ctx.global_variables[global_var_name]
    value_type = var_info.key_types[^1]
    table_id = var_info.slot
    (value_conversion, key_param_arr, key_copy_block, total_key_size) = get_combined_key_info(var_info)

  if value_type == "bytes32":
    value_conversion = "tmp_val"
  elif value_type in @["wei_value", "uint128"]:
    value_conversion = "tmp_val.to_uint128"
  else:
    raise newException(ParserError, "Unsupported StorageTable '{value_type}' value type.")

  var new_proc = parseStmt(fmt"""
    proc {new_proc_name}({key_param_arr.join(",")}): {value_type} =
      var
        tmp_val: bytes32
        combined_key {{.noinit.}}: array[{total_key_size}, byte]
{key_copy_block}
      tmp_val = getTableValue({table_id}.int32, combined_key)
      {value_conversion}
    """)
  return (new_proc, new_proc_name)
