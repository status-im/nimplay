#!/bin/bash

export WASM_LLVM_BIN="./llvm-wasm/bin/"

function print_contract () {
    wasm_file=$1
    echo "${wasm_file} eWASM bytecode:"
    echo "0x"`xxd -p $wasm_file | tr -d '\n'`
}

nimble examples

if [ $? -eq 0 ]; then
    print_contract examples/hello.wasm
fi
