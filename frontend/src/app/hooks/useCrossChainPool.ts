import { wagmiConfig } from "@/app/config/WagmiConfig";
import { allowedChainids, eventSigs, poolMapping } from "@/app/config/generalConfig";
import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { AbiEvent, parseAbiItem } from "viem";
import { getLogs } from "viem/actions";
import { useAccount, useChainId, useClient, useReadContract, useReadContracts } from "wagmi";
import { Deposit, Pool, UserDeposit } from "../config/interfaces";
import { crossChainPoolAbi } from "../abis/crossChainPoolAbi";
import usePoolCreatedEvents from "./usePoolCreatedEvents";



export default function useCrossChainPool({
    poolAddress
}: {
    poolAddress?: `0x${string}`
}) {
    const publicClient = useClient({ config: wagmiConfig })
    const chainId = useChainId() as allowedChainids
    const { address: userAddress } = useAccount()
    const [allPools, setAllpools] = useState<(`0x${string}` | undefined)[] | undefined>()
    const [userDeposits, setUserDeposits] = useState<UserDeposit[] | undefined>()

    const { logs } = usePoolCreatedEvents()

    useEffect(() => {
        if (logs)
            setAllpools(logs?.map(l => l.args.pool))
    }, [logs])



    // methods:
    // calculateLPTinExchangeOfUnderlying(uint256 _amountOfUnderlyingToDeposit)
    // calculateAmountToRedeem(uint256 _lptAmount)
    // calculateBuckleAppFees(uint256 _value)
    // getCcipFeesForTeleporting(uint256 _value, address _to) 
    // getCCipFeesForDeposit(uint256 _value)
    // function getCCipFeesForRedeem(uint256 _lptAmount, address _to)
    // getUnderlyingToken()
    // getCrossChainSenderAndSelector()
    // getOtherChainUnderlyingToken()
    // getCrossChainBalances()
    // getTotalProtocolBalances()
    // getValueOfOneLpt()
    // getRedeemValueForLP(uint256 _lptAmount)
    // getGasLimitValues()

    const { data } = useReadContracts({
        contracts: allPools?.flatMap(poolAddress => {
            return [{
                abi: crossChainPoolAbi,
                address: poolAddress,
                functionName: "calculateAmountToRedeem",
                args: [
                    1e18
                ]
            },
            {
                abi: crossChainPoolAbi,
                address: poolAddress,
                functionName: "getCrossChainSenderAndSelector",
                args: []
            }]
        }) as any,

    })

    useEffect(() => {
        console.log(data)
    }, [data])
    // useEffect(() => {
    //     const x = poolAddresses?.map(poolAddress => {
    //         return {
    //             abi: crossChainPoolAbi,
    //             address: poolAddress,
    //             functionName: "calculateAmountToRedeem",
    //             args: [
    //                 1e18
    //             ]
    //         }

    //     })
    //     console.log(x)
    // })



    // todo need to group deposits by pool and sum up all the deposits
    return { userDeposits }
}