import ../nimplay/ewasm_eei
import ../nimplay/nimplay_macros
import ../nimplay/types

# import endians
# import macros
import stint

# expandMacros:
contract("MyContract"):
    var
      a: uint256
      owner: address

    # proc default*() {.payable.}
    #   ...

    # proc publicGetSender(slot_number: uint256) =
    #   discard
      # dumpAstGen:
      #   tmp_func_get_storage_owner()
        # proc tmp_func_get_storage_owner(): address =
        #   var
        #     tmp: array[32, byte]
        #     position: array[32, byte]
        #     slot_number: uint32 = 1
        #   position[0..3] = cast[array[4, byte]](slot_number)
        #   storageLoad(position, addr tmp)
        #   var output: address
        #   output[0..20] = tmp[0..20]
        #   return output

    # proc get_value*(): uint128 {.payable.} =
    #   var ba: array[16, byte]
    #   getCallValue(addr ba)
    #   var val: Stuint[128]
    #   {.pragma: restrict, codegenDecl: "$# __restrict $#".}
    #   let r_ptr {.restrict.} = cast[ptr array[128, byte]](addr val)
    #   for i, b in ba:
    #     r_ptr[i] = b
    #   return val

    proc ret_bytes32*(in_a: bytes32): bytes32 =
        return in_a

    # proc get_value*(): uint128 {.payable.} =
    #   return msg.value

      # var b: array[16, byte]
      # var N = 16
      # for i in 0 ..< N:
      #   b[N-1 - i] = a[i]
      # return Uint128.fromBytesBE(b)

    # proc test_out*(aaa: uint128): uint128 =
    #   return 1222233344.stuint(128)

    # proc test_out_256*(): uint256 =
    #     return 1222233344.stuint(256)

    # proc get_storage*(): uint256 =
    #   return self.a

    # proc set_storage*(in_a: uint256) =
    #   self.a = in_a

    # proc set_storage*(a: uint256) =
    #   discard

    # proc set_storage*() =
    #     var
    #       pos = 0.stuint(32).toByteArrayBE
    #       value = 999999999999999.stuint(256).toByteArrayBE
    #     storageStore(pos, addr value)

    #   return msg.sender

    # proc tmp_func_get_storage_owner(slot_number: uint256): address =
    #   var tmp: array[32, byte]
    #   var position = slot_number.toByteArrayBE
    #   storageLoad(position, addr tmp)
    #   var output: address
    #   output[0..19] = tmp[12..31]
    #   return output

    # proc addition(in_a: uint256, in_b: uint256): uint256 =
    #   return in_a + in_b

    # proc get*(): uint256 =
    #   var tmp: array[32, byte]
    #   var pos = 0.stuint(32).toByteArrayBE
    #   storageLoad(pos, addr tmp)
    #   return Uint256.fromBytesBE(tmp)

    # proc set*() =
    #   var tmp = 556677.stuint(256).toByteArrayBE
    #   var pos = 0.stuint(32).toByteArrayBE
    #   storageStore(pos, addr tmp)

    # proc get_storage*(slot_number: uint256): uint256 =
    #   var tmp: uint256
    #   var pos = cast[bytes32](slot_number)
    #   storageLoad(pos, addr tmp)
    #   return tmp

    # proc set_storage*(slot_number: uint256, value: uint256) =
    #   var tmp: array[32, byte] = value.toByteArrayBE
    #   var pos = cast[bytes32](slot_number)
    #   storageStore(pos, addr tmp)
    
    # proc setOwner(in_owner: address) =
    #   self.owner = in_owner

    # proc getOwner(): address =
    #   return self.owner

    # proc get_sender222(): address =
    #  if true:
    #     return msg.sender

    # proc get_sender(): address =
    #  if true:
    #     return msg.sender

    # getCaller(addr tmp_addr)

    # blacklist storageStore
    # proc hello333(a: uint256): uint256 =
    #   discard

    # proc hello(a: uint256): uint256 =

    # dumpAstGen:
      #   let c: uint256 = Uint256.fromBytesBE(b)
      #   case a:
      #   else:
      #     discard
      #   var a = hello(1.uint256)
      #   var b: array[32, byte]
      #   callDataCopy(addr b, 4, 32)
      #   var c: uint256 = Uint256.fromBytesBE(b)

      # bigEndian32(addr selector, addr selector)

        # hello(a)
        # var selector: uint32
        # callDataCopy(selector, 0)
        # case selector
        # of 0x9993021a'u32:
        #   discard
        # else:
        #   revert(nil, 0)

      # dumpAstGen:  
        # var res {.noinit.}: uint256
      # dumpAstGen:
      #   var res = hello(a)
      #   var res_a = res.toByteArrayBE
      #   finish(addr res_a, 256)
        # finish(nil, 0)
      # dumpAstGen:
      #   bigEndian32(addr selector, addr selector)
      # return (123).stuint(256)

    # proc AllWorksToken() {.discardable.} =
    #   var b: array[32, byte] = (77877).stuint(256).toByteArrayBE()
    #   finish(addr b, 32)

    # proc world(a: uint256, b: uint256): uint256 =
    #     return a + b

    # proc do_nothing(a: uint256, b: uint256) =
    #   discard

    # func addition(a: uint256, b: uint256): uint256 =
    #   return a + b

    # proc hellonone() =
    #   discard

    # proc addition(a: uint256, b: uint256): uint256 =
    #   return a + b

# contract("MyContract"):
#     lib: from("lib/...")

#     proc hello(): uint256 =
#       lib.sha500()



# library A:
  
#   # public init() 
#   #   owner
#   # selfdestruct()
#   # special_func(aaa)


# contract B(A):
#  $$$$
#  $$$$
#  $$$$
#  $$$$
#  $$$$
