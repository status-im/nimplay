import ../eth_contracts
import ../eth_macros

import endians
import macros
import stint

expandMacros:
  contract("MyContract"):

    proc get_sender(): address =
      var tmp_addr: address
      getCaller(addr tmp_addr)
      return tmp_addr

    # getCaller(addr tmp_addr)
    # proc addition(a: uint256, b: uint256): uint256 =
    #   return a + b

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
