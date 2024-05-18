import { wagmiConfig } from "@/app/config/WagmiConfig";
import { allowedChainids, eventSigs, poolMapping } from "@/app/config/generalConfig";
import { useQuery } from "@tanstack/react-query";
import { useEffect } from "react";
import { AbiEvent, parseAbiItem } from "viem";
import { getLogs } from "viem/actions";
import { useChainId, useClient } from "wagmi";


export default function usePoolCreatedEvents() {
    const publicClient = useClient({ config: wagmiConfig })
    const chainId = useChainId() as allowedChainids


    const { data: logs } = useQuery({
        queryKey: ['logs', publicClient.uid],
        queryFn: () =>
            getLogs(publicClient, {
                address: poolMapping[chainId].factory,
                event: parseAbiItem(eventSigs.PoolFactory.poolCreated) as AbiEvent,
                fromBlock: poolMapping[chainId].fromBlock,
            })
    })

    const { data: allLogs } = useQuery({
        queryKey: ['allLogs', publicClient.uid],
        queryFn: () =>
            getLogs(publicClient, {
                address: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
                // event: parseAbiItem(eventSigs.PoolFactory.poolCreated) as AbiEvent,
                // fromBlock: 0n,
            })
    })

    useEffect(() => console.log("allLogs", allLogs, "0x54cCEe7e1eE9Aab153Da18b447a50D8282e1506F".toUpperCase()))

    return { logs }
}