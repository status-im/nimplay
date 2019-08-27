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
make get-nlvm-docker

```

### Using NLVM docker

```
make USE_NLVM=1 tools
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
