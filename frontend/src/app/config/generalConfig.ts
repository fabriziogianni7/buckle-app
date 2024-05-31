
import { poolFactoryAbi } from "../abis/poolFactoryAbi";
import * as all from "viem/chains";

const { ...chains } = all;
export enum Factories {
    SEPOLIA = 11155111,
    ARB_SEPOLIA = 421614,
    FUJI = 43113,
    AMOY = 80002,
}

export type allowedChainids = 11155111 | 421614 | 43113 | 80002

export const poolMapping = {
    //sepolia
    11155111: {
        factory: process.env.NEXT_PUBLIC_SEPOLIA_FACTORY as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            ccipBnM: "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05" as `0x${string}`,
            link: "0x779877A7B0D9E8603169DdbD7836e478b4624789" as `0x${string}`,
        },
        chainSelector: 16015286601757825753n,
        fromBlock: 6001174n
    },
    //arbitrumSepolia
    421614: {
        factory: process.env.NEXT_PUBLIC_ARB_SEPOLIA_FACTORY as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            ccipBnM: "0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D" as `0x${string}`,// this is another token I have in my wallet
            link: "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E" as `0x${string}`,// this is another token I have in my wallet

        },
        chainSelector: 3478487238524512106n,
        fromBlock: 49185964n
    },
    //fuji
    43113: {
        factory: process.env.NEXT_PUBLIC_FUJI as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            link: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846" as `0x${string}`,// this is another token I have in my wallet

        },
        chainSelector: 14767482510784806043n,
        fromBlock: 33514248n
    },
    //amoy
    80002: {
        factory: process.env.NEXT_PUBLIC_AMOY as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            link: "0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904" as `0x${string}`,// this is another token I have in my wallet

        },
        chainSelector: 14767482510784806043n,
        fromBlock: 7636551n
    }
}

export const generalConfig = {
    poolFactoryAbi,
    poolMapping,
    Factories
}


// todo use it
export const eventSigs = {
    PoolFactory: {
        poolCreated: "event PoolCreated(address indexed pool, address indexed tokenCurrentChain, address indexed tokenCrossChain, uint64 crosschainSelector)"
    },
    crossChainPool: {
        deposited: "event DepositedAndMintedLpt(address indexed lp,        uint256 indexed lptAmount,address indexed underlyingToken,        uint256 underlyingAmount,uint256 chainid)",
        teleported: "event TeleportStarted(uint256 indexed value, address indexed to)",
    }
}


export const ccipSelectorsTochain = {
    "16015286601757825753": "Sepolia",
    "3478487238524512106": "Arb Sepolia",
    "14767482510784806043": "C-Fuji",
    "16281711391670634445": "Amoy",
}

export type allowedChainSelectors =
    "16015286601757825753" |
    "3478487238524512106" |
    "14767482510784806043" |
    "16281711391670634445"

export type allowedTokens =
    "0xDbb077Ddec08E8b574186098359d30556AF6797D" |
    "0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357" |
    "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E" |
    "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846" |
    "0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904" |
    "0x779877A7B0D9E8603169DdbD7836e478b4624789" |
    "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05" |
    "0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D"


enum TokensToIcon {
    LINK = "icons-buckle/tokens/link-icon.svg",
    USDC = "icons-buckle/tokens/usdc-icon.svg",
    CCIP_BNM = "icons-buckle/tokens/ccip-bnm.svg"
}
enum TokensToName {
    LINK = "LINK",
    USDC = "USDC",
    CCIP_BNM = "CCIP_BNM"
}
enum NetworkIcons {
    ETHEREUM = "icons-buckle/chains/ethereum-icon.svg",
    ARBITRUM = "icons-buckle/chains/arbitrum-icon.svg",
    AVALANCHE = "icons-buckle/chains/avalanche-icon.svg",
    POLYGON = "icons-buckle/chains/polygon-icon.svg",
}

export const addressesToIcons = {
    "0xDbb077Ddec08E8b574186098359d30556AF6797D": TokensToIcon.USDC,
    "0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357": TokensToIcon.USDC,
    "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E": TokensToIcon.LINK,
    "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846": TokensToIcon.LINK,
    "0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904": TokensToIcon.LINK,
    "0x779877A7B0D9E8603169DdbD7836e478b4624789": TokensToIcon.LINK,
    "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05": TokensToIcon.CCIP_BNM,
    "0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D": TokensToIcon.CCIP_BNM,
}
export const addressesToNames = {
    "0xDbb077Ddec08E8b574186098359d30556AF6797D": TokensToName.USDC,
    "0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357": TokensToName.USDC,
    "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E": TokensToName.LINK,
    "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846": TokensToName.LINK,
    "0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904": TokensToName.LINK,
    "0x779877A7B0D9E8603169DdbD7836e478b4624789": TokensToName.LINK,
    "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05": TokensToName.CCIP_BNM,
    "0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D": TokensToName.CCIP_BNM,
}

export const selectorsToIcons = {
    "16015286601757825753": NetworkIcons.ETHEREUM,
    "3478487238524512106": NetworkIcons.ARBITRUM,
    "14767482510784806043": NetworkIcons.AVALANCHE,
    "16281711391670634445": NetworkIcons.POLYGON,
}


export const CCIP_EXPLORER_URL_ADDRESS = "https://ccip.chain.link/address/"
export const CCIP_EXPLORER_URL_TX = "https://ccip.chain.link/tx/"


export function getChain(chainId: number) {
    for (const chain of Object.values(chains)) {
        if (chain.id === chainId) {
            return chain;
        }
    }

    throw new Error(`Chain with id ${chainId} not found`);
}