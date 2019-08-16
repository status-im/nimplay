#!/bin/bash

rm -rf wabt
git clone --recursive https://github.com/WebAssembly/wabt wabt
mkdir -p wabt/build
cd wabt/build
cmake ".."
cmake  --build "."
