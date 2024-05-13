import { http, createStorage, cookieStorage } from 'wagmi'
import { arbitrumSepolia, sepolia } from 'wagmi/chains'

import { Chain, getDefaultConfig } from '@rainbow-me/rainbowkit'

const projectId = `${process.env.WALLET_CONNECT_ID}`;

const supportedChains: Chain[] = [sepolia, arbitrumSepolia];


export const wagmiConfig = getDefaultConfig({
    appName: "WalletConnection",
    projectId,
    chains: supportedChains as any,
    ssr: true,
    storage: createStorage({
        storage: cookieStorage,
    }),
    transports: supportedChains.reduce((obj, chain) => ({ ...obj, [chain.id]: http() }), {})
});