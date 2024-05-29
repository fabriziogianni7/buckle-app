'use client'
import { useEffect, useState } from "react";
import useAvailableTokensToTeleport from "../hooks/useAvailableTokensToTeleport";
import { Pool } from "../config/interfaces";
import SourceCard from "./teleporter/cards/SourceCard";
import DestinationCard from "./teleporter/cards/DestinationCard";
import { HSOverlay, ICollectionItem } from "preline/preline";
import TeleportModal from "./teleporter/modals/TeleportModal";


export interface Network {
  pools: Pool[]
}
export default function Teleport() {
  const [chainSelector, setChainSelector] = useState<string>()
  const [poolAddress, setPoolAddress] = useState<`0x${string}` | undefined>()
  const [tokenToBridge, setTokenToBridge] = useState<`0x${string}` | undefined>()
  const [amountToBridge, setAmountToBridge] = useState<number>()

  const { poolsAndTokens } = useAvailableTokensToTeleport(chainSelector as string)

  const setCorrectAmountToBridge = (amount: number) => {
    const finalValue = amount * 1e18
    setAmountToBridge(finalValue)
  }

  const getPoolFromToken = () => {
    if (tokenToBridge && poolsAndTokens) {
      const poolAddress = poolsAndTokens.find((pool) => pool.tokenCurrentChain == tokenToBridge)
      setPoolAddress(poolAddress?.pool)
    }
  }

  const openModal = () => {
    const modal = HSOverlay.getInstance('#teleport-modal' as unknown as HTMLElement, true) as ICollectionItem<HSOverlay>;
    modal.element.open();
  }

  useEffect(() => { getPoolFromToken() }, [tokenToBridge])


  useEffect(() => { console.log("test", chainSelector) }, [chainSelector])
  return (
    <main className="flex min-h-screen flex-col justify-center p-24">
      <div >
        <div className="max-w-5xl mx-auto px-2 xl:px-0 pt-8 lg:pt-2 pb-12">
          <h1 className="font-semibold text-slate-300 text-5xl md:text-6xl">
            <span className="bg-clip-text bg-gradient-to-tr from-yellow-500 to-yellow-900  text-transparent">Teleport Tokens </span>
            to many networks with low fees.
          </h1>
          <div className="max-w-4xl">
            <p className="mt-5 text-neutral-400 text-lg">
              Powered By Chainlink CCIP
            </p>
          </div>
        </div>
      </div>
      <div className="max-w-5xl mx-auto px-2 xl:px-0 pt-8 lg:pt-2 pb-12">
        <div className="flex flex-col gap-6 mt-5 
      lg:space-x-20 
      sm:flex-row sm:items-center sm: sm:mt-0 sm:ps-5">
          <SourceCard
            title="Starting Network"
            subtitle="Chose Token to bridge and How much you need to bridge"
            poolsAndTokens={poolsAndTokens}
            selectedToken={tokenToBridge}
            setTokenToBridge={setTokenToBridge}
            setAmountToBridge={setCorrectAmountToBridge}
          />

          <DestinationCard title="Destination Network" subtitle="Chose where you want the tokens"
            setDestinationSelector={setChainSelector}
          />
        </div >
        <div className="flex justify-center mt-4">
          <button type="button" className="py-3 px-40 mt-4 inline-flex items-center gap-x-10 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-slate-300 dark:hover:bg-neutral-800disabled:opacity-50 "
            data-hs-overlay="#teleport-modal"
            onClick={() => openModal()}
          >
            Teleport ⚡️
          </button>

        </div>
      </div>
      <TeleportModal
        poolAddress={poolAddress}
        chainSelector={chainSelector}
        tokenToBridge={tokenToBridge}
        amountToBridge={amountToBridge} />
    </main>
  );
}
