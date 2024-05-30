import usePoolCreatedEvents from "./usePoolCreatedEvents";
import { Pool } from "../config/interfaces";
import { useEffect, useState } from "react";


export default function useAvailableTokensToTeleport(selectedNetwork: string) {
    const { poolCreatedEvents } = usePoolCreatedEvents()
    const [poolsAndTokens, setPools] = useState<Pool[]>()

    useEffect(() => {
        if (poolCreatedEvents && selectedNetwork) {
            const pools: Pool[] = poolCreatedEvents?.map(((l: any) => l?.args as Pool)) as Pool[]
            const filteredPools: Pool[] = pools.filter((p) => p.crosschainSelector?.toString() == selectedNetwork)

            setPools(filteredPools)

        }
    }, [poolCreatedEvents, selectedNetwork])

    return { poolsAndTokens }

}