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



export default function useCrossChainPool() {
    const publicClient = useClient({ config: wagmiConfig })
    const chainId = useChainId() as allowedChainids
    const { address: userAddress } = useAccount()
    const [allPools, setAllpools] = useState<(`0x${string}` | undefined)[] | undefined>()
    const [balanceList, setBalanceList] = useState<any>()

    const { poolCreatedEvents }: { poolCreatedEvents: any } = usePoolCreatedEvents()

    useEffect(() => {
        if (poolCreatedEvents)
            console.log("ok")
        setAllpools(poolCreatedEvents?.map((l: any) => l?.args?.pool))
    }, [poolCreatedEvents])


    const { data: balances } = useReadContracts({
        contracts: allPools?.flatMap(poolAddress => {
            return [{
                abi: crossChainPoolAbi,
                address: poolAddress,
                functionName: "getTotalProtocolBalances"
            }]

        }) as any,

    })

    useEffect(() => {
        if (balances && allPools) {
            const newArr = allPools.map((poolAddress: any, index: number) => {
                const result = balances[index]?.result as any
                if (result) {
                    return {
                        poolAddress,
                        balance: result[0] as any
                    }

                }
            })
            setBalanceList(newArr)
        }
    }, [balances])





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






    // todo need to group deposits by pool and sum up all the deposits
    return { balanceList }
}