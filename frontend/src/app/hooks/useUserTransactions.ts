import { wagmiConfig } from "@/app/config/WagmiConfig";
import { allowedChainids, eventSigs, poolMapping } from "@/app/config/generalConfig";
import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { AbiEvent, parseAbiItem } from "viem";
import { getLogs } from "viem/actions";
import { useAccount, useBlockNumber, useChainId, useClient } from "wagmi";
import { UserDeposit, UserDepositEvent, UserTeleportEvent, UserTeleport } from "../config/interfaces";
import usePoolCreatedEvents from "./usePoolCreatedEvents";



export default function useUserTransactions() {
    const publicClient = useClient({ config: wagmiConfig })
    const chainId = useChainId() as allowedChainids
    const { address: userAddress } = useAccount()
    const [allPools, setAllpools] = useState<(`0x${string}` | undefined)[] | undefined>()
    const [allUserDesposits, setAllUserDesposits] = useState<(`0x${string}` | undefined)[] | undefined>()
    const [userDeposits, setUserDeposits] = useState<UserDeposit[] | undefined>()
    const [depositEvents, setDepositEvents] = useState<any | undefined>()
    const [teleportEvents, setTeleportEvents] = useState<any | undefined>()
    const [userTeleports, setUserTeleports] = useState<UserTeleport[] | undefined>()

    const { data: latestBlock } = useBlockNumber({
        chainId
    })

    const { poolCreatedEvents }: { poolCreatedEvents: any } = usePoolCreatedEvents()

    /////////////////////////////////
    ////// all deposit events //////
    /////////////////////////////////


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
                                        address: allPools as any,
                                        event: parseAbiItem(eventSigs.crossChainPool.deposited) as AbiEvent,
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
                                        address: allPools as any,
                                        event: parseAbiItem(eventSigs.crossChainPool.deposited) as AbiEvent,
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
                    setDepositEvents(promResult)
                }

            } catch (error) {
                console.log(error)
            }



        }
        fetchLogsFunction()


    }, [latestBlock, chainId])


    useEffect(() => {
        if (depositEvents) {
            const deposits = depositEvents.map((d: UserDepositEvent) => {
                return {
                    poolAddress: d.address,
                    lptAmount: d.args.lptAmount,
                    underlyingAmount: d.args.underlyingAmount,
                    txHash: d.transactionHash
                }
            })
            setUserDeposits(deposits)
        }
    }, [depositEvents])


    /////////////////////////////////
    ////// all teleport events //////
    /////////////////////////////////

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
                                        address: allPools as any,
                                        event: parseAbiItem(eventSigs.crossChainPool.teleported) as AbiEvent,
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
                                        address: allPools as any,
                                        event: parseAbiItem(eventSigs.crossChainPool.teleported) as AbiEvent,
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
                    setTeleportEvents(promResult)
                }

            } catch (error) {
                console.log(error)
            }



        }
        fetchLogsFunction()


    }, [latestBlock, chainId])


    // const { data: teleportEvents } = useQuery<UserTeleportEvent | any>({
    //     queryKey: ['teleportsEvent', publicClient.uid],
    //     queryFn: () =>
    //         getLogs(publicClient, {
    //             address: allPools as any,
    //             event: parseAbiItem(eventSigs.crossChainPool.teleported) as AbiEvent,
    //             fromBlock: poolMapping[chainId].fromBlock,
    //             args: {
    //                 to: userAddress,
    //             }
    //         })
    // })


    useEffect(() => {
        if (teleportEvents) {
            const teleports = teleportEvents.map((d: UserTeleportEvent) => {
                return {
                    poolAddress: d.address,
                    value: d.args.value,
                    to: d.args.to,
                    txHash: d.transactionHash
                }
            })
            setUserTeleports(teleports)
        }
    }, [teleportEvents])


    // const { data: symbol } = useReadContracts({
    //     abi: crossChainPoolAbi,
    //     address: poolAddress,
    //     functionName: "calculateAmountToRedeem",
    //     args: [
    //         amount
    //     ]
    // })







    // todo need to group deposits by pool and sum up all the deposits
    return { userDeposits, userTeleports }
}