// Adapted from https://github.com/paritytech/srml-contracts-waterfall/

import { ApiPromise, SubmittableResult, WsProvider } from "@polkadot/api";
import { Abi } from '@polkadot/api-contract';
import testKeyring from "@polkadot/keyring/testing";
import { u8aToHex } from "@polkadot/util";
import { randomAsU8a } from "@polkadot/util-crypto";
import { KeyringPair } from "@polkadot/keyring/types";
import { Option } from "@polkadot/types";
import { Address, ContractInfo, Hash } from "@polkadot/types/interfaces";

import { ALICE, CREATION_FEE, WSURL } from "./consts";
import {
  callContract,
  instantiate,
  getContractStorage,
  putCode
} from "./utils";

// This is a test account that is going to be created and funded each test.
const keyring = testKeyring({ type: "sr25519" });
const alicePair = keyring.getPair(ALICE);
let testAccount: KeyringPair;
let api: ApiPromise;

beforeAll((): void => {
  jest.setTimeout(30000);
});

beforeEach(
  async (done): Promise<() => void> => {
    api = await ApiPromise.create({ provider: new WsProvider(WSURL) });
    testAccount = keyring.addFromSeed(randomAsU8a(32));

    return api.tx.balances
      .transfer(testAccount.address, CREATION_FEE.muln(3))
      .signAndSend(alicePair, (result: SubmittableResult): void => {
        if (
          result.status.isFinalized &&
          result.findRecord("system", "ExtrinsicSuccess")
        ) {
          console.log("New test account has been created.");
          done();
        }
      });
  }
);

describe("Nimplay Hellow World", () => {
  test("Can deploy and execute", async (done): Promise<void> => {
    const codeHash = await putCode(
      api,
      testAccount,
      "../../../examples/substrate/hello_world.wasm"
    );
    expect(codeHash).toBeDefined();
    const address: Address = await instantiate(
      api,
      testAccount,
      codeHash,
      "0x00",
      CREATION_FEE
    );
    expect(address).toBeDefined();
    await callContract(api, testAccount, address, "0x00");
    done();
  });
});

describe("Nimplay Storage Setter", () => {
  test("Setter: Can deploy and execute", async (done): Promise<void> => {
    // See https://github.com/paritytech/srml-contracts-waterfall/issues/6 for info about
    // how to get the STORAGE_KEY of an instantiated contract

    const STORAGE_KEY = (new Uint8Array(32)).fill(2);
    // Deploy contract code on chain and retrieve the code hash
    const codeHash = await putCode(
      api,
      testAccount,
      "../../../examples/substrate/setter.wasm"
    );
    expect(codeHash).toBeDefined();

    // Instantiate a new contract instance and retrieve the contracts address
    const address: Address = await instantiate(
      api,
      testAccount,
      codeHash,
      "0x00",
      CREATION_FEE
    );
    expect(address).toBeDefined();

    const initialValue: Uint8Array = await getContractStorage(
      api,
      address,
      STORAGE_KEY
    );
    expect(initialValue).toBeDefined();
    expect(initialValue.toString()).toEqual("");

    await callContract(api, testAccount, address, "0x00");
    var val_hex = "03".repeat(32);
    // "0x00" indicates calling "Set" Action
    await callContract(api, testAccount, address, "0x00" + val_hex);
    const newValue = await getContractStorage(api, address, STORAGE_KEY);
    expect(newValue.toString()).toEqual("0x" + val_hex);

    done();
  });
});
