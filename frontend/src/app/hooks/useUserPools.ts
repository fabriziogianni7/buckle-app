import { wagmiConfig } from "@/app/config/WagmiConfig";
import { allowedChainids, eventSigs, poolMapping } from "@/app/config/generalConfig";
import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { AbiEvent, parseAbiItem } from "viem";
import { getLogs } from "viem/actions";
import { useAccount, useChainId, useClient } from "wagmi";
import { Deposit, Pool, UserDeposit } from "../config/interfaces";



export default function useUserPools() {
    const publicClient = useClient({ config: wagmiConfig })
    const chainId = useChainId() as allowedChainids
    const { address: userAddress } = useAccount()
    const [allPools, setAllpools] = useState<(`0x${string}` | undefined)[] | undefined>()
    const [userDeposits, setUserDeposits] = useState<UserDeposit[] | undefined>()




    const { data: logs } = useQuery({
        queryKey: ['logs', publicClient.uid],
        queryFn: () =>
            getLogs(publicClient, {
                address: poolMapping[chainId].factory,
                event: parseAbiItem(eventSigs.PoolFactory.poolCreated) as AbiEvent,
                fromBlock: poolMapping[chainId].fromBlock,
            })
    })

    const { data: deposits } = useQuery<Deposit[] | any>({
        queryKey: ['deposits', publicClient.uid],
        queryFn: () =>
            getLogs(publicClient, {
                address: allPools as `0x${string}`[],
                event: parseAbiItem(eventSigs.crossChainPool.deposited) as AbiEvent,
                fromBlock: poolMapping[chainId].fromBlock,
            })
    })


    useEffect(() => {
        const pools = logs?.map((l => l.args as Pool)).map(p => p.pool)
        setAllpools(pools)
    }, [logs])

    useEffect(() => {
        let mappedArray: UserDeposit[] = []

        const userDeposits =
            deposits?.filter((d: Deposit) => d.args.lp == userAddress)
                .map((d: Deposit) => {
                    return {
                        pool: d.address,
                        args: d.args
                    }
                })
                .reduce((_: any, current: { pool: `0x${string}`; args: Deposit["args"]; }) => {
                    const elementIndex = mappedArray.findIndex((el) => el.pool == current.pool)
                    if (elementIndex >= 0) {
                        mappedArray[elementIndex].args.lptAmount += current.args.lptAmount
                        mappedArray[elementIndex].args.underlyingAmount += current.args.underlyingAmount
                    } else {
                        mappedArray.push(current)
                    }
                    return mappedArray
                }, mappedArray)

        setUserDeposits(userDeposits)
    }, [deposits])
    // todo need to group deposits by pool and sum up all the deposits
    return { userDeposits }
}