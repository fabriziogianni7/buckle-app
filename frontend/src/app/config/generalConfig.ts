import { crossChainPoolAbi } from "../abis/crossChainPoolAbi";
import { poolFactoryAbi } from "../abis/poolFactoryAbi";

export enum Factories {
    SEPOLIA = 11155111,
    ARB_SEPOLIA = 421614,
    FUJI = 43113,
}

export type allowedChainids = 11155111 | 421614 | 43113

export const poolMapping = {
    //sepolia
    11155111: {
        factory: "0x78f2aA2F6A8B92a0539bA56dDEcfFc0c18e4fEBD" as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            usdc: "0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357" as `0x${string}`,
        },
        chainSelector: 16015286601757825753n,
        fromBlock: 5913915n
    },
    //arbitrumSepolia
    421614: {
        factory: "0xa460Ec0F081f5F89F0420f2cb9A93760537ef7A5" as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            usdc: "0xDbb077Ddec08E8b574186098359d30556AF6797D" as `0x${string}`,// this is another token I have in my wallet
            link: "0xb1D4538B4571d411F07960EF2838Ce337FE1E80E" as `0x${string}`,// this is another token I have in my wallet

        },
        chainSelector: 3478487238524512106n,
        fromBlock: 45047743n
    },
    //fuji
    43113: {
        factory: "0x54cCEe7e1eE9Aab153Da18b447a50D8282e1506F" as `0x${string}`, // should be put somewhere else maybe
        tokens: {
            link: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846" as `0x${string}`,// this is another token I have in my wallet

        },
        chainSelector: 14767482510784806043n,
        fromBlock: 33069552n
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
        deposited: "event DepositedAndMintedLpt(address indexed lp, uint256 indexed lptAmount, uint256 indexed underlyingAmount)",
        teleported: "event TeleportStarted(uint256 indexed value, address indexed to)",
    }
}


export const ccipSelectorsTochain = {
    "16015286601757825753": "Sepolia",
    "3478487238524512106": "Arb Sepolia",
    "14767482510784806043": "C-Fuji",
}

export type allowedChainSelectors =
    "16015286601757825753" |
    "3478487238524512106" |
    "14767482510784806043"


enum TokensToIcon {
    LINK = "icons-buckle/tokens/link-icon.svg",
    USDC = "icons-buckle/tokens/usdc-icon.svg"
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
}

export const selectorsToIcons = {
    "16015286601757825753": NetworkIcons.ETHEREUM,
    "3478487238524512106": NetworkIcons.ARBITRUM,
    "14767482510784806043": NetworkIcons.AVALANCHE,
    "0": NetworkIcons.POLYGON,
}


export const CCIP_EXPLORER_URL_ADDRESS = "https://ccip.chain.link/address/"
export const CCIP_EXPLORER_URL_TX = "https://ccip.chain.link/tx/"

