# Installation

The NimPlay installation is currently managed through a simple [Makefile](https://github.com/status-im/nimplay/blob/master/Makefile).
To use it, you shouldn't need anything else besides _BASH_, _GNU Make_, _CMake_ and _Python_.

## Obtaining NLVM

To make development of nimplayer easier, NimPlay uses NLVM (https://github.com/arnetheduck/nlvm/tree/master/nlvm) which is a LLVM based Nim compiler. To fetch the latest version of NLVM in either AppImage or Docker form, use one of the following commands: 

```
make get-nlvm-appimage
```

or

```
make get-nlvm-docker
```

## Building the examples

This repo includes a number of examples such as the [King of the Hill](https://github.com/status-im/nimplay/blob/master/examples/king_of_the_hill.nim) contract. To build them, use the following commands:

```
git submodule update --init
make get-wabt
make tools
make examples
```

