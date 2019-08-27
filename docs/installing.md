# Installing

To make development of nimplayer easier, NimPlay uses NLVM(https://github.com/arnetheduck/nlvm/tree/master/nlvm).
Which is a LLVM based Nim compiler. To make setup a NimPlay environment, either Nim + Clang or NLVM Docker image can be used, the minimum requriement for this would be _GNU Make_ and _BASH_.

## Using Nim + Clang Docker

```
make get-nimclang-docker
make tools
make examples
```


## Using NLVM docker

```
make get-nlvm-docker
make tools
make examples
```
