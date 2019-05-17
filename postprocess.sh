
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

# LEN=$(( `stat --printf="%s" $WASM_FILE` / 2))
# WASM_HEX=`xxd -p $WASM_FILE | tr -d '\n'`
# out=""
# s=$WASM_HEX
# for (( i=0; i<${#s}; i += 2 )); do
#    out=$out"\\${s:$i:2}"
# done
# WASM_HEX=$out
# DEPLOY_FILE=/tmp/wasm.deploy.tmp

# cat > $DEPLOY_FILE <<- EOM
# (module
#  (import "ethereum" "finish" (func \$finish (param i32 i32)))
#  (memory 1000)
#  (data (i32.const 0) "${WASM_HEX}")
#  (export "main" (func \$main))
#  (export "memory" (memory 0))
#  (func \$main
#     (call \$finish (i32.const 0) (i32.const ${LEN})))
# )
# EOM
# cat $DEPLOY_FILE
# wat2wasm $DEPLOY_FILE -o $WASM_FILE".deploy"
# rm /tmp/wasm.tmp
