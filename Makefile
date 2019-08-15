

.PHONY: clean tools get-nlvm examples

get-nlvm:
	curl -L https://github.com/arnetheduck/nlvm/releases/download/continuous/nlvm-x86_64.AppImage -o tools/nlvm
	chmod +x tools/nlvm


tools:
	nim c -d:release --out:tools/abi_gen tools/abi_gen.nim 
	nim c -d:release --out:tools/k256_sig tools/k256_sig.nim


clean:
	rm -f *.wasm *.ll *.wat


examples:	
	@$(MAKE) -C examples


install: tools get-nlvm
