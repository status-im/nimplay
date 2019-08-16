
NLVM=./tools/nlvm
# NLVM=nim


.PHONY: get-nlvm examples
get-nlvm-appimage:
	curl -L https://github.com/arnetheduck/nlvm/releases/download/continuous/nlvm-x86_64.AppImage -o tools/nlvm
	chmod +x tools/nlvm

.PHONY: get-nlvm-docker
get-nlvm-docker:
	docker pull jacqueswww/nlvm

.PHONY: get-wabt
get-wabt:
	"./tools/get_wabt.sh"
	mv wabt tools/

.PHONY: tools
tools:
	nim c -d:release --out:tools/abi_gen tools/abi_gen.nim 
	nim c -d:release --out:tools/k256_sig tools/k256_sig.nim

.PHONY: clean
clean:
	rm -f *.wasm *.ll *.wat


examples:	
	@$(MAKE) -C examples
