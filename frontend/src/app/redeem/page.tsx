'use client'
import { useEffect, useState } from "react";


import Deposits from "./redeemer/Deposits";
import { Pool } from "../config/interfaces";
import useUserPools from "../hooks/useUserPools";


export default function Redeem() {

  const { userDeposits } = useUserPools()


  return (
    <main className="flex min-h-screen flex-col items-center justify-start p-24">
      <div >
        <div className="max-w-5xl mx-auto px-2 xl:px-0 pt-8 lg:pt-2 pb-12">
          <h1 className="font-semibold text-slate-300 text-5xl md:text-6xl">
            <span className="bg-clip-text bg-gradient-to-tr from-yellow-500 to-yellow-900  text-transparent">Redeem Your Tokens </span> <br />
            Burn LP tokens, get earnings crosschain.
          </h1>
        </div>
      </div>
      <Deposits deposits={userDeposits} />
    </main>
  );
}
