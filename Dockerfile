FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y software-properties-common wget curl gcc && \
    wget https://nim-lang.org/download/nim-0.20.2-linux_x64.tar.xz && \
    tar xf nim-0.20.2-linux_x64.tar.xz && \
    cd nim-0.20.2 && \
    ./install.sh /usr/bin && \
    cd .. && \
    rm -rf nim-0.20.2 && \
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    apt-add-repository "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main" && \
    apt-get install -y clang-8 lld-8 libc6-dev-i386 && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-8 1000 && \
    update-alternatives --install /usr/bin/wasm-ld wasm-ld /usr/bin/wasm-ld-8 1000 && \
    apt-get remove -y curl wget gcc software-properties-common && \
    apt-get auto-remove -y && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/nim"]


# apt-get install libc6-dev-i386
# apt-get install lld-8
# update-alternatives --install /usr/bin/wasm-ld wasm-ld /usr/bin/wasm-ld-8 1000
