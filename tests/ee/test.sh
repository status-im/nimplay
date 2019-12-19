#!/bin/bash
CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
RUST_VERSION="nightly"
REPO_DIR="ewasm-scout"
REPO_URL="https://github.com/ewasm/scout.git"
SCOUT_TEST_FILES=./*.yml


if [[ -e $REPO_DIR ]]; then
    rm -v $REPO_DIR/*.yml
    cp $SCOUT_TEST_FILES $REPO_DIR/
    cd $REPO_DIR
    git pull
else
    git clone $REPO_URL $REPO_DIR
    rm -v $REPO_DIR/*.yml
    cp $SCOUT_TEST_FILES $REPO_DIR/
    cd $REPO_DIR
fi


if [[ ! -e $CARGO_HOME ]]; then
    echo "Fetching rustup"
    curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path --default-toolchain $RUST_VERSION
fi

rustup target add wasm32-unknown-unknown
rustup component add rustfmt
rustup update
cargo install chisel 
# make build
cargo build --release
# make test
# target/release/phase2-scout $SCOUT_TEST_FILE

for testfile in $SCOUT_TEST_FILES
do
    echo $testfile
    RUST_LOG=debug target/release/phase2-scout $testfile || exit
    break
done
