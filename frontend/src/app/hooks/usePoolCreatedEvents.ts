import { wagmiConfig } from "@/app/config/WagmiConfig";
import { allowedChainids, eventSigs, poolMapping } from "@/app/config/generalConfig";
import { useEffect, useState } from "react";
import { AbiEvent, parseAbiItem } from "viem";
import { getLogs } from "viem/actions";
import { useBlockNumber, useChainId, useClient } from "wagmi";


export default function usePoolCreatedEvents() {
    const publicClient = useClient({ config: wagmiConfig })
    const chainId = useChainId() as allowedChainids
    const { data: latestBlock } = useBlockNumber({ chainId })
    const [poolCreatedEvents, setPoolCreatedEvents] = useState<any>()

    useEffect(() => {

        const fetchLogsFunction = async () => {
            try {
                if (latestBlock) {
                    const totalBlocks = Number(latestBlock - poolMapping[chainId].fromBlock)
                    const chunkLen = 2045
                    const nChunks = Math.floor(totalBlocks / chunkLen)
                    const promArr = []
                    for (let i = 0; i <= nChunks; i++) {
                        if (chainId == 43113 || chainId == 80002) {
                            const fromBlock = BigInt(Number(poolMapping[chainId].fromBlock) + chunkLen * i)
                            const toBlock = BigInt(Number(fromBlock) + chunkLen)

                            const query = new Promise<any>(async (res, rej) => {
                                try {
                                    res(await getLogs(publicClient, {
                                        address: poolMapping[chainId].factory,
                                        event: parseAbiItem(eventSigs.PoolFactory.poolCreated) as AbiEvent,
                                        fromBlock,
                                        toBlock
                                    }))
                                } catch (error) {
                                    rej(error)
                                }
                            })
                            promArr.push(query)

                        }
                        else {
                            const query = new Promise<any>(async (res, rej) => {
                                try {
                                    res(await getLogs(publicClient, {
                                        address: poolMapping[chainId].factory,
                                        event: parseAbiItem(eventSigs.PoolFactory.poolCreated) as AbiEvent,
                                        fromBlock: poolMapping[chainId].fromBlock,
                                    }))
                                } catch (error) {
                                    rej(error)
                                }
                            })
                            promArr.push(query)
                            break
                        }
                    }
                    const promResult = (await Promise.allSettled(promArr)).flatMap((el: any) => el.value)
                        .filter((el: any) => el != undefined)
                    setPoolCreatedEvents(promResult)
                }

            } catch (error) {
                console.log(error)
            }



        }
        fetchLogsFunction()

    }, [latestBlock, chainId])

    useEffect(() => {
        // debugger
        console.log("poolCreatedEvents", poolCreatedEvents)
    }, [poolCreatedEvents])


    return { poolCreatedEvents }
}