FROM ubuntu:18.04

ADD . /code
WORKDIR /code

RUN apt-get update && \
    apt-get install -y software-properties-common wget curl gcc g++ git cmake && \
    wget https://nim-lang.org/download/nim-0.20.2-linux_x64.tar.xz && \
    tar xf nim-0.20.2-linux_x64.tar.xz && \
    cd nim-0.20.2 && \
    ./install.sh /usr/bin && \
    cd .. && \
    rm -rf nim-0.20.2 && \
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    apt-add-repository "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main" && \
    apt-get install -y clang-8 lld-8 libc6-dev-i386 && \
    rm -rf wabt && \
    git clone --recursive https://github.com/WebAssembly/wabt wabt && \
    mkdir -p wabt/build && \
    cd wabt/build && \
    cmake ".." && \
    cmake  --build "." && \
    make install && \
    cd ../../ && \
    rm -rf wabt && \
    nim c -d:release -p:/code/vendor/nimcrypto -p:/code/vendor/stint -p:/code/vendor/nim-stew/ --out:/usr/bin/k256_sig tools/k256_sig.nim && \
    nim c -d:release -p:/code/vendor/nimcrypto -p:/code/vendor/stint -p:/code/vendor/nim-stew/ --out:/usr/bin/abi_gen tools/abi_gen.nim && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-8 1000 && \
    update-alternatives --install /usr/bin/wasm-ld wasm-ld /usr/bin/wasm-ld-8 1000 && \
    apt-get remove -y cmake curl wget gcc software-properties-common && \
    apt-get auto-remove -y && \
    rm -rf /var/lib/apt/lists/* 

ENTRYPOINT ["/usr/bin/nim"]


# apt-get install libc6-dev-i386
# apt-get install lld-8
# update-alternatives --install /usr/bin/wasm-ld wasm-ld /usr/bin/wasm-ld-8 1000
