import { AbiEvent } from "viem";
import { poolFactoryAbi } from "../abis/poolFactoryAbi";

export enum Factories {
    SEPOLIA = 11155111,
    ARB_SEPOLIA = 421614,
}
export const poolMapping = {
    //sepolia
    11155111: {
        factory: "0x04722a980f2F48696446A3F3017520dCbe8527Cc" as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            dai: "0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357" as `0x${string}`,
        },
        chainSelector: 16015286601757825753n,
        fromBlock: 5913915n
    },
    //arbitrumSepolia
    421614: {
        factory: "0x26bBdCc59D8c9d5f269635A1C13208d6DeE6d98e" as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            usdc: "0xDbb077Ddec08E8b574186098359d30556AF6797D" as `0x${string}`,// this is another token I have in my wallet

        },
        chainSelector: 3478487238524512106n,
        fromBlock: 44617940n
    }
}

export const generalConfig = {
    poolFactoryAbi,
    poolMapping,
    Factories
}
export type allowedChainids = 11155111 | 421614


// todo use it
export const eventSigs = {
    PoolFactory: {
        poolCreated: "event PoolCreated(address indexed pool, address indexed tokenCurrentChain, address indexed tokenCrossChain, uint64 crosschainSelector)"
    }
}


export const allTokens = {
    "0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357": "DAI",
    "0xDbb077Ddec08E8b574186098359d30556AF6797D": "KEY"
}


export const ccipSelectorsTochain = {
    "16015286601757825753": "Sepolia",
    "3478487238524512106": "Arb Sepolia",
}

export type allowedChainSelectors =
    "16015286601757825753" |
    "3478487238524512106"


