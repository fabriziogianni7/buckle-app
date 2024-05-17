import { wagmiConfig } from "@/app/config/WagmiConfig";
import { allowedChainSelectors, allowedChainids, ccipSelectorsTochain, eventSigs, poolMapping } from "@/app/config/generalConfig";
import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { AbiEvent, parseAbiItem } from "viem";
import { getLogs } from "viem/actions";
import { useChainId, useClient } from "wagmi";


export default function useCurrentChainSelector() {
    const chainId = useChainId() as allowedChainids
    const [selector, setSelector] = useState<allowedChainSelectors | undefined>()
    const [chainName, setChainName] = useState("")
    useEffect(() => {
        setSelector(poolMapping[chainId].chainSelector.toString() as allowedChainSelectors)

        setChainName(ccipSelectorsTochain[poolMapping[chainId].chainSelector.toString() as allowedChainSelectors])
    }, [chainId])

    return { selector, chainId, chainName }
}