import { poolFactoryAbi } from "../abis/poolFactoryAbi";




export type allowedChainids = 11155111 | 421614
enum Factories {
    SEPOLIA = 11155111,
    ARB_SEPOLIA = 421614,
}

const poolMapping = {
    11155111: {
        factory: "0x30C07770a7F5576B2c36D38d8D145762867432EA" as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            usdc: "0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357" as `0x${string}`,
        },
        chainSelector: 16015286601757825753,
    },
    421614: {
        factory: "0x8F44aFD0e319aBcEdaee0599Ad7a9c0C4f4A7Fd8" as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            usdc: "0xDbb077Ddec08E8b574186098359d30556AF6797D" as `0x${string}`,// this is another token I have in my wallet

        },
        chainSelector: 3478487238524512106
    }
}

export const generalConfig = {
    poolFactoryAbi,
    poolMapping,
    Factories
}
