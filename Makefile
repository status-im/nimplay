pwd=$(shell pwd)
NLVM_PATH_PARAMS=-p:/code/vendors/nimcrypto -p:/code/vendors/stint -p:/code/vendors/nim-stew/
DOCKER_NLVM=docker run -w /code/ -v $(pwd):/code/ jacqueswww/nlvm
DOCKER_NLVM_C=$(DOCKER_NLVM) $(NLVM_PATH_PARAMS) c

.PHONY: get-nlvm-docker
get-nlvm-docker:
	docker pull jacqueswww/nlvm

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

examples:
	@$(MAKE) -C examples
