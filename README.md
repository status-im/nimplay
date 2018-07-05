# Ethereum smart contracts in Nim

Disclaimer: WIP

This is a sample of how building eWASM contracts in Nim is possible.
Requirements:
* clang 6.0 or later with WebAssembly support. Most likely has to be built manually.
* `wasm2wat` and `wat2wasm` from [wabt (WebAssembly binary toolkit)](https://github.com/WebAssembly/wabt)
* [optional] [wasm-gc](https://github.com/alexcrichton/wasm-gc) optimizer

## Compiling examples
```
export WASM_LLVM_BIN=/path/to/llvm/bin/folder
nimble examples
```

## License

Licensed under one of the following:

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT
