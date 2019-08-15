nlvm=../tools/nlvm
postprocess=../tools/eth_postprocess.sh
# NFLAGS=-d:release --nlvm.target=wasm32 --gc:none -l:--no-entry -l:--allow-undefined -d:clang -l:--strip-all --noMain
# NFLAGS=-d:release --nlvm.target=wasm32 --gc:none -l:--compress-relocations -l:--no-entry -l:--allow-undefined -l:--strip-all --noMain
NFLAGS= --nlvm.target=wasm32 --gc:none -l:--no-entry -l:--allow-undefined -d:clang

king_of_the_hill:
	$(nlvm) c -c $(NFLAGS) king_of_the_hill.nim
	$(postprocess) king_of_the_hill.wasm

# %.nim:
# 	$(nlvm) c  %.nim 
