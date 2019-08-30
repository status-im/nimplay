# Installation

The NimPlay installation is currently managed through a simple [Makefile](https://github.com/status-im/nimplay/blob/master/Makefile).
To use it, you shouldn't need anything else besides _BASH_, _GNU Make_, _CMake_ and _Python_.

## Obtaining Nim + Clang Docker

```
make get-nimclang-docker
```

## Obtaining NLVM docker

To use NLVM instead of Nim + Clang use 

```
git submodule update --init
make get-wabt
make USE_NLVM=1 tools
make get-nlvm-docker
```

### Using NLVM docker

```
make USE_NLVM=1 examples
```

## Using Nim + Clang Docker

```
git submodule update --init
make get-wabt
make get-nimclang-docker 
```

## Building the examples

This repo includes a number of examples such as the [King of the Hill](https://github.com/status-im/nimplay/blob/master/examples/king_of_the_hill.nim) contract. To build them, use the following commands:

```
make examples
```
or
```
make USE_NLVM=1 examples
```

## Deploying to EWASM Testnet

Nimplay ships with a deploy python script (requires web3py installed). This script key can be used to deploy a contract

Place 32 byte private key, hex encoded in `.priv_key_hex`
```
cat > .priv_key_hex
0x0000000000000000000000000000000000000000000000000000000000000000
```

To deploy a contract use:
```
./tools/deploy.py  examples/king_of_the_hill.wasm
```

The following enviroment variables are consumed by the deploy.py script

| Varname         |Default (unset)                 |
|---              |---                             |
| PRIVATE_KEY_FILE| .priv_key_hex                  |
| RPC_URL         |  http://ewasm.ethereum.org:8545|
| WAT2WASM        | ./tools/wabt/bin/wat2wasm      |
| WASM2WAT        | ./tools/wabt/bin/wasm2wat      |

### ModuleNotFoundError: No module named 'web3'

This means web3py is not installed, please install using pip:

```
pip install --user web3
```

Also see how to make a [virtualenv](https://www.liquidweb.com/kb/creating-virtual-environment-ubuntu-16-04/) if you want your packages isolated.
