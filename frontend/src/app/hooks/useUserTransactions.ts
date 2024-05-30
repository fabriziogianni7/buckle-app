import { wagmiConfig } from "@/app/config/WagmiConfig";
import { allowedChainids, eventSigs, poolMapping } from "@/app/config/generalConfig";
import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { AbiEvent, parseAbiItem } from "viem";
import { getLogs } from "viem/actions";
import { useAccount, useChainId, useClient } from "wagmi";
import { UserDeposit, UserDepositEvent, UserTeleportEvent, UserTeleport } from "../config/interfaces";
import { crossChainPoolAbi } from "../abis/crossChainPoolAbi";
import usePoolCreatedEvents from "./usePoolCreatedEvents";



export default function useUserTransactions() {
    const publicClient = useClient({ config: wagmiConfig })
    const chainId = useChainId() as allowedChainids
    const { address: userAddress } = useAccount()
    const [allPools, setAllpools] = useState<(`0x${string}` | undefined)[] | undefined>()
    const [allUserDesposits, setAllUserDesposits] = useState<(`0x${string}` | undefined)[] | undefined>()
    const [userDeposits, setUserDeposits] = useState<UserDeposit[] | undefined>()
    const [userTeleports, setUserTeleports] = useState<UserTeleport[] | undefined>()

    const { poolCreatedEvents }: { poolCreatedEvents: any } = usePoolCreatedEvents()

    /////////////////////////////////
    ////// all deposit events //////
    /////////////////////////////////

    const { data: depositEvents } = useQuery<UserDepositEvent | any>({
        queryKey: ['depositsEvents', publicClient.uid],
        queryFn: () =>
            getLogs(publicClient, {
                address: allPools as any,
                event: parseAbiItem(eventSigs.crossChainPool.deposited) as AbiEvent,
                fromBlock: poolMapping[chainId].fromBlock,
                args: {
                    lp: userAddress,
                }
            })
    })

    useEffect(() => {
        if (poolCreatedEvents)
            setAllpools(poolCreatedEvents?.map((l: any) => l?.args?.pool))
    }, [poolCreatedEvents])

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


    const { data: teleportEvents } = useQuery<UserTeleportEvent | any>({
        queryKey: ['teleportsEvent', publicClient.uid],
        queryFn: () =>
            getLogs(publicClient, {
                address: allPools as any,
                event: parseAbiItem(eventSigs.crossChainPool.teleported) as AbiEvent,
                fromBlock: poolMapping[chainId].fromBlock,
                args: {
                    to: userAddress,
                }
            })
    })


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