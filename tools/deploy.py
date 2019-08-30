#!/usr/bin/env python3
# Deployment script for NimPlay contracts
# requirements:
import os
import sys

import argparse
import json
import web3
import textwrap
import subprocess
import tempfile

from web3 import Web3
from web3.providers import HTTPProvider

PRIVATE_KEY = os.environ.get('PRIVATE_KEY')
PRIVATE_KEY_FILE = os.environ.get('PRIVATE_KEY_FILE', '.priv_key_hex')
RPC_URL = os.environ.get('RPC_URL', 'http://ewasm.ethereum.org:8545')
WAT2WASM = os.environ.get('WAT2WASM', './tools/wabt/bin/wat2wasm')
WASM2WAT = os.environ.get('WASM2WAT', './tools/wabt/bin/wasm2wat')


if not PRIVATE_KEY and PRIVATE_KEY_FILE:
    PRIVATE_KEY = open(PRIVATE_KEY_FILE, 'r').read()

if not PRIVATE_KEY:
    print('Private Key required, user either PRIVATE_KEY or PRIVATE_KEY_FILE')
    sys.exit(1)


def watb_util(binary, code):
    with tempfile.NamedTemporaryFile() as in_file, tempfile.NamedTemporaryFile() as out_file:
        outb = code.encode() if isinstance(code, str) else code
        in_file.write(outb)
        in_file.flush()
        completed_process = subprocess.run([binary, in_file.name, '-o',  out_file.name])
        out_file.seek(0)
        b = out_file.read()
        return b


def wasm2wat(code):
    return watb_util(WASM2WAT, code)


def wat2wasm(code):
    return watb_util(WAT2WASM, code)


def get_abi(fpath):
    cmdline = ['./tools/abi_gen', fpath.replace('wasm', 'nim')]
    completed_process = subprocess.run(
        cmdline,
        stdout=subprocess.PIPE,
    )
    if completed_process.returncode != 0:
        print(completed_process.stdout)
        print(completed_process.stderr)
        raise Exception('Could not get ABI')
    return json.loads(completed_process.stdout)


def create_deploy_bytecode(fpath):
    with open(fpath, 'rb') as f:
        wasmb = f.read()
        hexb = Web3.toHex(wasmb)[2:]
        total_len = len(hexb) // 2
        escaped_hexb = "\\" + "\\".join(hexb[x:x+2] for x in range(0, len(hexb), 2))
        code = textwrap.dedent(f"""
        (module
          (type (;0;) (func (param i32 i32)))
          (type (;1;) (func))
          (import "ethereum" "finish" (func (;0;) (type 0)))
          (func (;1;) (type 1)
            i32.const 0
            i32.const {total_len}
            call 0)
          (memory (;0;) 100)
          (export "memory" (memory 0))
          (export "main" (func 1))
          (data (;0;) (i32.const 0) "{escaped_hexb}"))
        """)
        print(code)
        deploy_wasmb = wat2wasm(code)
    abi = get_abi(fpath)
    return abi, Web3.toHex(deploy_wasmb)


def main(contract_file, get_shell=False):
    abi, bytecode = create_deploy_bytecode(contract_file)

    w3 = Web3(HTTPProvider(RPC_URL))
    acct = w3.eth.account.privateKeyToAccount(PRIVATE_KEY)
    contract_ = w3.eth.contract(
        abi=abi,
        bytecode=bytecode
    )

    construct_txn = contract_.constructor().buildTransaction({
        'from': acct.address,
        'nonce': w3.eth.getTransactionCount(acct.address),
        'gas': 2000000,
        'gasPrice': w3.toWei('1', 'gwei')}
    )

    # Deploy
    print(f"Account address: {acct.address}")
    receipt = None
    signed = acct.signTransaction(construct_txn)
    tx_hash = w3.eth.sendRawTransaction(signed.rawTransaction)
    print(f'Deployed Transaction: {tx_hash.hex()}')
    w3.eth.waitForTransactionReceipt(tx_hash)
    print('Mined transaction')
    receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    print(f'Contract Address: {receipt["contractAddress"]}')
    print(f"Success?: {receipt['status'] == 1}")
    print(receipt)

    if get_shell:
        import pdb; pdb.set_trace()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("contract_file")
    parser.add_argument("--get-shell", help="Break to pdb debugger right after deploying.", action="store_true")
    args = parser.parse_args()
    main(args.contract_file, args.get_shell)
