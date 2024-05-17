import { wagmiConfig } from "@/app/config/WagmiConfig";
import { allowedChainids, eventSigs, poolMapping } from "@/app/config/generalConfig";
import { useQuery } from "@tanstack/react-query";
import { AbiEvent, parseAbiItem } from "viem";
import { getLogs } from "viem/actions";
import { useChainId, useClient, useReadContract } from "wagmi";
import usePoolCreatedEvents from "./usePoolCreatedEvents";
import { Pool } from "../config/interfaces";
import { crossChainPoolAbi } from "../abis/crossChainPoolAbi";
import { useEffect, useState } from "react";
import { readContracts } from '@wagmi/core'


export default function useAvailableTokensToTeleport(selectedNetwork: string) {
    const { logs } = usePoolCreatedEvents()
    const [poolsAndTokens, setPools] = useState<Pool[]>()

    useEffect(() => {
        if (logs && selectedNetwork) {
            const pools: Pool[] = logs?.map((l => l.args as Pool)) as Pool[]
            console.log("selectedNetwork", selectedNetwork)
            // crosschainSelector: 3478487238524512106n
            // pool: "0xeC4Ce2Ac23a8EB3F4000d02a049b6e68857Ae7C6"
            // tokenCrossChain: "0xDbb077Ddec08E8b574186098359d30556AF6797D"
            // tokenCurrentChain: "0x3308ff248A0Aa6EB7499A39C4c26ADF526825B0d"
            const filteredPools: Pool[] = pools.filter((p) => p.crosschainSelector?.toString() == selectedNetwork)
            console.log("filteredPools", filteredPools)

            setPools(filteredPools)

        }
    }, [logs, selectedNetwork])

    return { poolsAndTokens }

}