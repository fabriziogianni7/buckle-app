'use client'
import { useEffect, useState } from "react";
import { generalConfig, allowedChainids } from "../../config/generalConfig";
import Card from "./Card";
import { useWriteContract } from 'wagmi'
import { useChainId } from 'wagmi'

export default function PoolCreator() {
    const [destinationNetwork, setDestinationNetwork] = useState<allowedChainids>()
    const [token, setToken] = useState<"usdc">()
    const chainId = useChainId() as allowedChainids
    const { writeContract, error } = useWriteContract()

    useEffect(() => { console.log("error", error) }, [error])
    const createPoolPairs = () => {

        const abi = generalConfig.poolFactoryAbi
        const poolMapping = generalConfig.poolMapping
        if (destinationNetwork && token) {
            writeContract({
                abi,
                address: poolMapping[chainId].factory,
                functionName: "deployCCPools",
                args: [
                    poolMapping[destinationNetwork].factory, // _receiverFactory
                    poolMapping[chainId].tokens[token], // _underlyingTokenOnSourceChain
                    poolMapping[destinationNetwork].tokens[token], //_underlyingTokenOnDestinationChain
                    poolMapping[destinationNetwork].chainSelector, //_destinationChainSelector
                    "test" // _poolName
                ]
            })
        }
    }



    return (
        <div className="flex flex-col bg-white border shadow-sm rounded-xl dark:bg-neutral-800 dark:border-neutral-300 dark:shadow-neutral-900/70 px-4 py-4">
            <Card title="Select Source Network" SourceOrDestination="Source"
                setDestinationNetwork={setDestinationNetwork}
                setToken={setToken}
                createPoolPairs={createPoolPairs}
            />
        </div>
    );
}