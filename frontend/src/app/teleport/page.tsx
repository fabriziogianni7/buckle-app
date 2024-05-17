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
// 1st step: chose destination network
// 2nd step: chose available token

// for 1 and 2:

// get pools in current chain from event,
//   get selector from pool
//   filter the tokens based on the destination chain chosen by the _underlyingTokenOnSourceChain



// 3rd step: chose amount
// 4th step: send tx
// 4a: forecast ccip fees
// 4b: forecast buckle fees
// 4c: approve pool to spend token
// 4d: send teleport tx
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


  useEffect(() => { console.log("test", poolsAndTokens) }, [poolsAndTokens])
  return (
    <main className="flex min-h-screen flex-col items-center justify-start p-24">
      <h1 className="text-4xl dark:text-white mb-16">Chose what token you want to teleport to another network</h1>
      <div className="flex flex-col gap-2 mt-5 lg:space-x-40 sm:flex-row sm:items-center sm:justify-end sm:mt-0 sm:ps-5">
        <SourceCard
          title="Starting Network"
          subtitle="Chose Token to bridge and How much you need to bridge"
          poolsAndTokens={poolsAndTokens}
          selectedToken={tokenToBridge}
          setTokenToBridge={setTokenToBridge}
          setAmountToBridge={setCorrectAmountToBridge}
        />
        <button type="button" className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-white dark:hover:bg-neutral-800disabled:opacity-50"
          data-hs-overlay="#teleport-modal"
          onClick={() => openModal()}
        >
          Teleport ⚡️
        </button>
        <DestinationCard title="Destination Network" subtitle="Chose where you want the tokens"
          setDestinationSelector={setChainSelector}
        />
      </div>
      <TeleportModal
        poolAddress={poolAddress}
        chainSelector={chainSelector}
        tokenToBridge={tokenToBridge}
        amountToBridge={amountToBridge} />
    </main>
  );
}
