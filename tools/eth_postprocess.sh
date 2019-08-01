
WASM_FILE=$1

# set -ex
if which wasm-gc > /dev/null
then
  wasm-gc "$WASM_FILE" # Optimize
else
  echo wasm-gc not found. The resulting wasm files will not be optimized
fi

# Replace "env" with "ethereum"
wasm2wat "$WASM_FILE" |
 sed 's/(import "env" /(import "ethereum" /g' |
 sed 's/(export "__heap_base" (global 1))//g' |
 sed 's/(export "__data_end" (global 2))//g' > /tmp/wasm.tmp

wat2wasm -o "$WASM_FILE" /tmp/wasm.tmp

