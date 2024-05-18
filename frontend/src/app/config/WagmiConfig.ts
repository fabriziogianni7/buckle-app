import { http, createStorage, cookieStorage, useClient } from 'wagmi'
import { arbitrumSepolia, avalancheFuji, sepolia } from 'wagmi/chains'

import { Chain, getDefaultConfig } from '@rainbow-me/rainbowkit'

import { getLogs } from 'viem/actions'


const projectId = `${process.env.NEXT_PUBLIC_WALLET_CONNECT_ID}`;

const supportedChains: Chain[] = [sepolia, arbitrumSepolia, avalancheFuji];

export const wagmiConfig = getDefaultConfig({
    appName: "WalletConnection",
    projectId,
    chains: supportedChains as any,
    ssr: true,
    storage: createStorage({
        storage: cookieStorage,
    }),
    transports: supportedChains.reduce((obj, chain) => ({ ...obj, [chain.id]: http() }), {}),
});

