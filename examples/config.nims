--os:standalone
--cpu:i386
--cc:clang
--gc:regions
--nomain
--opt:speed

let llBin = getEnv("WASM_LLVM_BIN")
if llBin.len == 0:
  raise newException(Exception, "WASM_LLVM_BIN env var is not set")

let llTarget = "wasm32-unknown-unknown-wasm"

switch("passC", "--target=" & llTarget)
switch("passL", "--target=" & llTarget)

switch("passC", "-I./include")


switch("clang.exe", llBin & "/clang")
switch("clang.linkerexe", llBin & "/clang")
switch("clang.options.linker", "-nostdlib -Wl,--no-entry,--allow-undefined,--strip-all")
