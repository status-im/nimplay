
WASM_FILE=$1

set -ex
if which wasm-gc > /dev/null
then
  wasm-gc "$WASM_FILE" # Optimize
else
  echo wasm-gc not found. The resulting wasm files will not be optimized
fi

wasm2wat="tools/wabt/build/wasm2wat"
wat2wasm="tools/wabt/build/wat2wasm"
# Replace "env" with "ethereum"
$wasm2wat "$WASM_FILE" |
 sed 's/(import "env" /(import "ethereum" /g' |
 sed  '/(export.*memory\|main.*/! s/(export.*//g' > /tmp/wasm.tmp

$wat2wasm -o "$WASM_FILE" /tmp/wasm.tmp

