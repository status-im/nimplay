#!/bin/bash

WASM_FILE=$1

set -ex

#wasm2wat="tools/wabt/build/wasm2wat"
#wat2wasm="tools/wabt/build/wat2wasm"

wasm2wat="docker run --entrypoint=wasm2wat -w /code/ -v $(pwd):/code/ jacqueswww/nimclang "
wat2wasm="docker run --entrypoint=wat2wasm -w /code/ -v $(pwd):/code/ jacqueswww/nimclang "

# Replace "env" with "ethereum"
$wasm2wat "$WASM_FILE" |
 sed  '/(export.*deploy\|call.*/! s/(export.*//g' > ./wasm.tmp

$wat2wasm -o "$WASM_FILE" ./wasm.tmp

rm ./wasm.tmp
