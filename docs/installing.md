 # Installing

*Please Note*: Nimplay is still in very early developmental stages, the below lengthy installtion steps will be refined in the future.

This is a sample of how building eWASM contracts in Nim is possible.
Requirements:
* clang 7.0 or later with WebAssembly support. Most likely has to be built manually.
* 32bit version of libc. On linuxes it is usually provided by the package manager.
* `wasm2wat` and `wat2wasm` from [wabt (WebAssembly binary toolkit)](https://github.com/WebAssembly/wabt). They need to be in the `PATH`.
* [optional] [wasm-gc](https://github.com/alexcrichton/wasm-gc) optimizer

## Compiling examples

```
export WASM_LLVM_BIN=/path/to/llvm/bin/folder
nimble tools
nimble examples
```

## Troubleshooting

* **Emscripten doesn't work!** It is not expected to. Use clang with wasm target enabled.
* **clang is difficult to build.** No, it's easy. Follow these steps:

```
tag=release_70
INSTALL_PREFIX=$(pwd)/llvm-wasm
git clone --depth 1 --branch $tag https://github.com/llvm-mirror/llvm.git
cd llvm/tools
git clone --depth 1 --branch $tag https://github.com/llvm-mirror/clang
git clone --depth 1 --branch $tag https://github.com/llvm-mirror/lld
cd ..
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DLLVM_TARGETS_TO_BUILD= -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly ..
make -j 4 install
```

* **C compiler errors: headers not found.** Make sure you have 32bit libc installed and visible to your clang.
