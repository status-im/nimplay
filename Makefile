pwd=$(shell pwd)
POSTPROCESS=tools/eth_postprocess.sh
NLVM_PATH_PARAMS=-p:/code/vendors/nimcrypto -p:/code/vendors/stint -p:/code/vendors/nim-stew/
DOCKER_NLVM=docker run -w /code/ -v $(pwd):/code/ jacqueswww/nlvm
DOCKER_NLVM_C=$(DOCKER_NLVM) $(NLVM_PATH_PARAMS) c
NLVM_WAMS32_FLAGS= --nlvm.target=wasm32 --gc:none -l:--no-entry -l:--allow-undefined -d:clang
DOCKER_WASM32_C=$(DOCKER_NLVM) $(NLVM_PATH_PARAMS) $(NLVM_WAMS32_FLAGS) c

.PHONY: all
all: get-nlvm-docker tools examples

.PHONY: get-nlvm-docker
get-nlvm-docker:
	docker pull docker.io/jacqueswww/nlvm

.PHONY: get-wabt
get-wabt:
	"./tools/get_wabt.sh"
	mv wabt tools/

.PHONY: tools
tools:
	$(DOCKER_NLVM_C) -d:release --out:tools/k256_sig tools/k256_sig.nim
	$(DOCKER_NLVM_C) -d:release --out:tools/abi_gen tools/abi_gen.nim

.PHONY: clean
clean:
	rm -f *.wasm *.ll *.wat

.PHONY: get-nlvm examples
get-nlvm-appimage:
	curl -L https://github.com/arnetheduck/nlvm/releases/download/continuous/nlvm-x86_64.AppImage -o tools/nlvm
	chmod +x tools/nlvm

.PHONY: vendors
vendors:
	cd vendors
	git submodule update

.PHONY: king_of_the_hill
king_of_the_hill:
	$(DOCKER_WASM32_C) examples/king_of_the_hill.nim
	$(POSTPROCESS) examples/king_of_the_hill.wasm

.PHONY: examples
examples: king_of_the_hill
