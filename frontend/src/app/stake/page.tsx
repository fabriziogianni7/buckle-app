'use client'
import { useEffect, useState } from "react";


import Pools from "./staker/Pools";
import usePoolCreatedEvents from "@/app/hooks/usePoolCreatedEvents";
import { Pool } from "../config/interfaces";


export default function Stake() {
  const [poolList, setPoolList] = useState<Pool[]>()

  const { logs } = usePoolCreatedEvents()

  useEffect(() => {
    if (logs) {
      const logsElements: Pool[] = logs?.map((l => l.args as Pool))
      setPoolList(logsElements)
    }

  }, [logs])

  return (
    <main className="flex min-h-screen flex-col items-center justify-start p-24">
      <h1 className="text-4xl dark:text-white mb-16"> Stake into one pool to earn fees on cross chain bridges</h1>
      <Pools pools={poolList} />
    </main>
  );
}
