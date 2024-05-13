'use client'
import { WagmiProvider, cookieToInitialState } from 'wagmi'
import { wagmiConfig } from "./config/WagmiConfig"
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { RainbowKitProvider, darkTheme, lightTheme } from '@rainbow-me/rainbowkit'


const queryClient = new QueryClient()

type Props = {
    children: React.ReactNode;
    cookie?: string | null;
};

export default function Providers({
    children,
    cookie
}: Props) {
    const initialState = cookieToInitialState(wagmiConfig, cookie);
    return (
        <div>
            <WagmiProvider config={wagmiConfig} initialState={initialState}>
                <QueryClientProvider client={queryClient}>
                    <RainbowKitProvider
                        theme={lightTheme({
                            accentColor: "#0E76FD",
                            accentColorForeground: "white",
                            borderRadius: "large",
                            fontStack: "system",
                            overlayBlur: "small",
                        })}
                    >

                        {children}
                    </RainbowKitProvider>
                </QueryClientProvider>
            </WagmiProvider >
        </div>
    );
}
