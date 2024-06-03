'use client'
import { useEffect, useState } from "react";


import Pools from "./staker/Pools";
import usePoolCreatedEvents from "@/app/hooks/usePoolCreatedEvents";
import { Pool } from "../config/interfaces";
import useCrossChainPool from "../hooks/useCrossChainPool";


export default function Stake() {
  const [poolList, setPoolList] = useState<Pool[]>()

  const { poolCreatedEvents } = usePoolCreatedEvents()
  const { balanceList } = useCrossChainPool()

  const getPoolBalance = (poolAddress: `0x${string}`) => {
    if (balanceList) {
      const element = balanceList.find((el: {
        balance: number, poolAddress: `0x${string}`
      }) => el?.poolAddress == poolAddress)
      return element?.balance
    }

    return 0
  }

  useEffect(() => {
    if (poolCreatedEvents && balanceList) {
      const logsElements: Pool[] = poolCreatedEvents?.map(((l: any) => {
        return {
          ...l?.args,
          balance: getPoolBalance(l?.args.pool)
        } as Pool
      }
      ))
      setPoolList(logsElements)
    }

  }, [poolCreatedEvents, balanceList])

  return (
    <main className="flex min-h-screen flex-col justify-start p-24">
      <div >
        <div className="max-w-5xl mx-auto px-2 xl:px-0 pt-8 lg:pt-2 pb-12">
          <h1 className="font-semibold text-slate-300 text-5xl md:text-6xl">
            <span className="bg-clip-text bg-gradient-to-tr from-yellow-500 to-yellow-900  text-transparent">Stake into Buckle </span> <br />
            earn fees on every teleport.
          </h1>
        </div>
      </div>
      <Pools pools={poolList} />
    </main >
  );
}
