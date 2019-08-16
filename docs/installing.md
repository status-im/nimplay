# Installing

To make development of nimplayer easier, NimPlay uses NLVM(https://github.com/arnetheduck/nlvm/tree/master/nlvm).
Which is a LLVM based Nim compiler. To make setup a NimPlay environment, either AppImage (for Linux) or Docker can be used, the minimum requriement for this would be _GNU Make_ and _BASH_.

## Using NLVM App

```
make get-nlvm-appimage
make tools
make examples
```


## Using NLVM docker

```
make get-nlvm-docker
```
