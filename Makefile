user_id :=$(shell id -u $(shell whoami))
pwd=$(shell pwd)
POSTPROCESS=tools/eth_postprocess.sh
PATH_PARAMS=-p:/code/vendors/nimcrypto -p:/code/vendors/stint -p:/code/vendors/nim-stew/
# Use NLVM
DOCKER_NLVM=docker -w /code/ -v $(pwd):/code/ jacqueswww/nlvm
DOCKER_NLVM_C=$(DOCKER_NLVM) $(PATH_PARAMS) c
NLVM_WAMS32_FLAGS= --nlvm.target=wasm32 --gc:none -l:--no-entry -l:--allow-undefined -d:clang
DOCKER_NLVM_C=$(DOCKER_NLVM) $(PATH_PARAMS) $(NLVM_WAMS32_FLAGS) c
# Use nim + clang
DOCKER_NIM_CLANG=docker run -e HOME='/tmp/' --user $(user_id):$(user_id) -w /code/ -v $(pwd):/code/ --entrypoint="/usr/bin/nim" nimclang --verbosity:2 --d:release
DOCKER_NIM_CLANG_PASS_FLAGS = --passC:"--target=wasm32-unknown-unknown-wasm" \
--passL:"--target=wasm32-unknown-unknown-wasm" --passC:"-I./include" --clang.options.linker:"-nostdlib -Wl,--no-entry,--allow-undefined,--strip-all,--export-dynamic"

DOCKER_NIM_CLANG_FLAGS=$(DOCKER_NIM_CLANG_PASS_FLAGS) --os:standalone --cpu:i386 --cc:clang --gc:none --nomain
DOCKER_NIM_CLANG_C=$(DOCKER_NIM_CLANG) $(DOCKER_NIM_CLANG_FLAGS) $(PATH_PARAMS) c

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
	$(DOCKER_NLVM_C) examples/king_of_the_hill.nim
	$(POSTPROCESS) examples/king_of_the_hill.wasm

# .PHONY: examples
# examples: king_of_the_hill

nimexamples:
	$(DOCKER_NIM_CLANG_C) --out:examples/king_of_the_hill.wasm examples/king_of_the_hill.nim
	$(POSTPROCESS) examples/king_of_the_hill.wasm
