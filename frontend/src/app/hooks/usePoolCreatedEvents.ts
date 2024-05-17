import { wagmiConfig } from "@/app/config/WagmiConfig";
import { allowedChainids, eventSigs, poolMapping } from "@/app/config/generalConfig";
import { useQuery } from "@tanstack/react-query";
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

    return { logs }
}