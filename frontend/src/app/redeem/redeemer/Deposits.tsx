'use client'

import { HSOverlay, ICollectionItem } from "preline/preline";
import RedeemModal from "./modals/RedeemModal";
import { useState } from "react";
import { UserDeposit } from "@/app/config/interfaces";
import { CCIP_EXPLORER_URL_ADDRESS, ccipSelectorsTochain } from "@/app/config/generalConfig";
import { formatEther } from "viem";
import useCrossChainPool from "@/app/hooks/useCrossChainPool";


interface DepositsProps {
    deposits: UserDeposit[] | undefined
}



export default function Deposits({ deposits }: DepositsProps) {
    const [pool, setPool] = useState<`0x${string}` | undefined>()
    const [currentChainToken, setCurrentChainToken] = useState<`0x${string}` | undefined>()
    const [crossChainToken, setCrossChainToken] = useState<`0x${string}` | undefined>()

    useCrossChainPool()

    const openModal = (poolAddress: `0x${string}` | undefined) => {
        const modal = HSOverlay.getInstance('#deposit-modal' as unknown as HTMLElement, true) as ICollectionItem<HSOverlay>;
        setPool(poolAddress)
        modal.element.open();
    }

    return (
        <div className="flex flex-col">
            <div className="-m-1.5 overflow-x-auto">
                <div className="p-1.5 min-w-full inline-block align-middle">
                    <div className="overflow-hidden">
                        <table className="min-w-full">
                            <thead>
                                <tr key={1}>
                                    <th scope="col" className="px-6 py-3 text-start text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Pool Address</th>
                                    <th scope="col" className="px-6 py-3 text-start text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Liquidity Pool Token Amount</th>
                                    <th scope="col" className="px-6 py-3 text-start text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Underlying Token Amount</th>
                                    {/* <th scope="col" className="px-6 py-3 text-start text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Destination Network</th> */}
                                    <th scope="col" className="px-6 py-3 text-end text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Action</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-neutral-700">
                                {
                                    deposits && deposits.map((deposit: UserDeposit | any, i) => <tr key={i}>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-800 dark:text-neutral-200">{
                                            <a className="text-blue-600 hover:text-blue-800 hover:bg-blue-100 px-2 py-1 rounded"
                                                href={`${CCIP_EXPLORER_URL_ADDRESS}${deposit.pool}`}
                                                target="_blank"
                                            >
                                                {deposit.pool.substring(0, 30
                                                )}...

                                            </a>
                                        }</td>
                                        <td className="px-6 py-4 whitespace-nowrap te   t-sm text-gray-800 dark:text-neutral-200">{
                                            formatEther(deposit.args.lptAmount)
                                        }</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-800 dark:text-neutral-200">{
                                            formatEther(deposit.args.underlyingAmount)
                                        }</td>
                                        {/* <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-800 dark:text-neutral-200">{


                                        }</td> */}
                                        <td className="px-6 py-4 whitespace-nowrap text-end text-sm font-medium">
                                            <button type="button" className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-slate-300 dark:hover:bg-neutral-800disabled:opacity-50"
                                                data-hs-overlay="#deposit-modal"
                                                onClick={() => openModal(deposit.pool)}
                                            >
                                                Redeem
                                            </button>
                                        </td>
                                    </tr>)
                                }


                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <RedeemModal poolAddress={pool} currentChainTokenAddress={currentChainToken} poolName="Test Pool" crossChainTokenAddress={crossChainToken} />
        </div>
    )
}