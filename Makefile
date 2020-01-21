user_id :=$(shell id -u $(shell whoami))
pwd=$(shell pwd)
POSTPROCESS=tools/eth_postprocess.sh
PATH_PARAMS=-p:/code/vendor/nimcrypto -p:/code/vendor/stint -p:/code/vendor/nim-stew/
# Use NLVM
DOCKER_NLVM=docker run -e HOME='/tmp/' --user $(user_id):$(user_id) -w /code/ -v $(pwd):/code/ jacqueswww/nlvm
DOCKER_NLVM_C=$(DOCKER_NLVM) $(PATH_PARAMS) c
NLVM_WAMS32_FLAGS= --nlvm.target=wasm32 --gc:none -l:--no-entry -l:--allow-undefined -d:clang -d:release
DOCKER_NLVM_C=$(DOCKER_NLVM) $(PATH_PARAMS) $(NLVM_WAMS32_FLAGS) c
# Use nim + clang
DOCKER_NIM_CLANG=docker run -e HOME='/tmp/' --user $(user_id):$(user_id) -w /code/ -v $(pwd):/code/ --entrypoint="/usr/bin/nim" jacqueswww/nimclang --verbosity:2
CLANG_OPTIONS_LINKER=-nostdlib -Wl,--no-entry,--allow-undefined,--strip-all,--export-dynamic

# Ewasm
DOCKER_NIM_CLANG_C=$(DOCKER_NIM_CLANG) --cc:clang $(PATH_PARAMS) c
DOCKER_NIM_CLANG_PASS_FLAGS_EWASM = --passC:"--target=wasm32-unknown-unknown-wasm" \
--passL:"--target=wasm32-unknown-unknown-wasm" --passC:"-I./include" --clang.options.linker:"$(CLANG_OPTIONS_LINKER)"
DOCKER_NIM_CLANG_FLAGS_EWASM=$(DOCKER_NIM_CLANG_PASS_FLAGS_EWASM) --os:standalone --cpu:i386 --cc:clang --gc:none --nomain -d:release
DOCKER_NIM_CLANG_EWASM_C=$(DOCKER_NIM_CLANG) $(DOCKER_NIM_CLANG_FLAGS_EWASM) $(PATH_PARAMS) c

# Substrate
DOCKER_NIM_CLANG_PASS_FLAGS_SUBSTRATE = --passC:"--target=wasm32-unknown-unknown-wasm" \
--passL:"--target=wasm32-unknown-unknown-wasm" --passC:"-I./include" \
--clang.options.linker:"$(CLANG_OPTIONS_LINKER),--import-memory,--max-memory=131072"
DOCKER_NIM_CLANG_FLAGS_SUBSTRATE=$(DOCKER_NIM_CLANG_PASS_FLAGS_SUBSTRATE) --os:standalone --cpu:i386 --cc:clang --gc:none --nomain -d:release
SUBSTRATE_NIMC=$(DOCKER_NIM_CLANG) $(DOCKER_NIM_CLANG_FLAGS_SUBSTRATE) $(PATH_PARAMS) c

ifdef USE_NLVM
	NIMC=$(DOCKER_NLVM_C)
	EWASM_NIMC=$(DOCKER_NLVM_C)
else
	NIMC=$(DOCKER_NIM_CLANG_C)
	EWASM_NIMC=$(DOCKER_NIM_CLANG_EWASM_C)
endif

.PHONY: all
all: tools examples

.PHONY: get-nlvm-docker
get-nlvm-docker:
	docker pull docker.io/jacqueswww/nlvm

.PHONY: get-nimclang-docker
get-nimclang-docker:
	docker pull docker.io/jacqueswww/nimclang

.PHONY: get-wabt
get-wabt:
	rm -rf tools/wabt
	./tools/get_wabt.sh
	mv wabt tools/

.PHONY: tools
tools:
	$(NIMC) -d:release --out:tools/k256_sig tools/k256_sig.nim
	$(NIMC) -d:release --out:tools/abi_gen tools/abi_gen.nim

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
	git submodule update --init

.PHONY: ewasm_king_of_the_hill
ewasm_king_of_the_hill:
	$(EWASM_NIMC) --out:examples/king_of_the_hill.wasm examples/king_of_the_hill.nim
	$(POSTPROCESS) examples/king_of_the_hill.wasm

.PHONY: examples
ewasm-examples: ewasm_king_of_the_hill
	$(EWASM_NIMC) --out:examples/registry.wasm examples/registry.nim
	$(POSTPROCESS) examples/registry.wasm
	$(EWASM_NIMC) --out:examples/balances.wasm examples/balances.nim
	$(POSTPROCESS) examples/balances.wasm
	$(EWASM_NIMC) --out:examples/erc20.wasm examples/erc20.nim
	$(POSTPROCESS) examples/erc20.wasm
	$(EWASM_NIMC) --out:examples/default_func.wasm examples/default_func.nim
	$(POSTPROCESS) examples/default_func.wasm

.PHONY: ee-examples
ee-examples:
	$(EWASM_NIMC) --out:examples/ee/helloworld.wasm examples/ee/helloworld.nim
	$(EWASM_NIMC) --out:examples/ee/block_echo.wasm examples/ee/block_echo.nim

.PHONY: test-ee
test-ee: ee-examples
	cd tests/ee/; \
	   ./test.sh

SUBSTRATE_POSTPROCESS=tools/substrate_postprocess.sh

.PHONY: substrate-examples
substrate-examples:
	$(SUBSTRATE_NIMC) --out:examples/substrate/hello_world.wasm examples/substrate/hello_world.nim
	$(SUBSTRATE_POSTPROCESS) examples/substrate/hello_world.wasm
	$(SUBSTRATE_NIMC) --out:examples/substrate/setter.wasm examples/substrate/setter.nim
	$(SUBSTRATE_POSTPROCESS) examples/substrate/setter.wasm

.PHONY: test-substrate
test-substrate: substrate-examples	
	cd tests/substrate; \
		SUBSTRATE_PATH="${HOME}/.cargo/bin/substrate" ./test.sh
