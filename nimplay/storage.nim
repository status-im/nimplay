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

    if var_info.var_type != "uint256":
        raise newException(ParserError, "Only uint256 storage supported at the moment.")

    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(): uint256 =
        var
            tmp: array[32, byte]
            pos = {$slot_number}.stuint(32).toByteArrayBE
        storageLoad(pos, addr tmp)
        return Uint256.fromBytesBE(tmp)
    """)

    #[
    proc get*(): uint256 =
        var tmp: array[32, byte]
        var pos = 0.stuint(32).toByteArrayBE
        storageLoad(pos, addr tmp)
        return Uint256.fromBytesBE(tmp)
    ]#

    # var new_proc = parseStmt(fmt"""
    # proc {new_proc_name}(): address =
    #     var
    #         tmp: array[32, byte]
    #         pos = {$slot_number}.stuint(32).toByteArrayBE

    #     storageLoad(position, addr tmp)
    #     var output: address
    #     const N = 20
    #     for i in 0..<N:
    #        output[i] = tmp[i]
    #     return output
    # """)

    return (new_proc, new_proc_name)


proc generate_storage_set_func*(storage_keyword: string, global_ctx: GlobalContext): (NimNode, string) =
    var
        global_var_name = storage_keyword.split(".")[1]
        new_proc_name = fmt"set_{global_var_name}_in_storage"
        var_info = global_ctx.global_variables[global_var_name]
        slot_number = var_info.slot

    if var_info.var_type != "uint256":
        raise newException(ParserError, "Only uint256 storage supported at the moment.")

    var new_proc = parseStmt(fmt"""
    proc {new_proc_name}(value:uint256) =
        var
            tmp: array[32, byte] = value.toByteArrayBE
            pos = {$slot_number}.stuint(32).toByteArrayBE
        storageStore(pos, addr tmp)
    """)
    return (new_proc, new_proc_name)
