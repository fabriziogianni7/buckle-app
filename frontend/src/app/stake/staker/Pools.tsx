'use client'

// import { HSOverlay, ICollectionItem } from "preline/preline";
import DepositModal from "./modals/DepositModal";
import { useEffect, useState } from "react";
import { Pool } from "@/app/config/interfaces";
import { CCIP_EXPLORER_URL_ADDRESS, addressesToIcons, allowedChainSelectors, allowedTokens, ccipSelectorsTochain, selectorsToIcons } from "@/app/config/generalConfig";
import Image from 'next/image';
import { usePathname } from "next/navigation";
import { HSOverlay, ICollectionItem } from "preline";


interface PoolsProp {
    pools: Pool[] | undefined
}




export default function Pools({ pools }: PoolsProp) {
    const [pool, setPool] = useState<`0x${string}` | undefined>()
    const [currentChainToken, setCurrentChainToken] = useState<`0x${string}` | undefined>()
    const [crossChainToken, setCrossChainToken] = useState<`0x${string}` | undefined>()
    const path = usePathname();
    const [preline, setPreline] = useState<any>()

    useEffect(() => {
        const dynamicImport = async () => {
            const preline = (await import("preline/preline"))
            setPreline(preline)
            //  await import("preline/preline").

        }
        if (path) {
            dynamicImport()
        }
    }, [path])

    const openModal = (poolAddress: `0x${string}` | undefined, currentChainTokenAddress: `0x${string}` | undefined, crossChainTokenAddress: `0x${string}` | undefined) => {
        const modal = preline.HSOverlay.getInstance('#deposit-modal' as unknown as HTMLElement, true) as ICollectionItem<HSOverlay>;
        setPool(poolAddress)
        setCurrentChainToken(currentChainTokenAddress)
        setCrossChainToken(crossChainTokenAddress)
        modal.element.open();
    }

    useEffect(() => console.log(pools))
    return (
        <div className="flex flex-col">
            <div className="-m-1.5 overflow-x-auto">
                <div className="p-1.5 min-w-full inline-block align-middle">
                    <div className="overflow-hidden">
                        <table className="min-w-full">
                            <thead>
                                <tr key={1}>
                                    <th scope="col" className="px-6 py-3 text-start text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Pool Address</th>
                                    <th scope="col" className="px-6 py-3 text-start text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Token Address Source Network</th>
                                    <th scope="col" className="px-6 py-3 text-start text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Token Address Destination Network</th>
                                    <th scope="col" className="px-6 py-3 text-start text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Destination Network</th>
                                    <th scope="col" className="px-6 py-3 text-end text-xs font-medium text-gray-500 uppercase dark:text-neutral-500">Action</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200 dark:divide-neutral-700">
                                {
                                    pools && pools.map((pool: Pool, i) => <tr key={i}>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-800 dark:text-neutral-200">{
                                            <a className="text-blue-600 hover:text-blue-800 hover:bg-blue-100 px-2 py-1 rounded"
                                                href={`${CCIP_EXPLORER_URL_ADDRESS}${pool?.pool}`}
                                                target="_blank"

                                            >
                                                ${pool?.pool?.substring(0, 10)}...
                                            </a>
                                        }</td>
                                        <td className="px-6 py-4 whitespace-nowrap te  t-sm text-gray-800 dark:text-neutral-200 ">
                                            <div className="flex">


                                                <Image
                                                    priority
                                                    src={addressesToIcons[pool?.tokenCurrentChain! as allowedTokens]}
                                                    alt="deposit"
                                                    width={20}
                                                    height={20}
                                                    className="mr-4"
                                                />
                                                <a className="text-blue-600 hover:text-blue-800 hover:bg-blue-100 px-2 py-1 rounded"
                                                    href={`${CCIP_EXPLORER_URL_ADDRESS}${pool?.tokenCurrentChain}`}
                                                    target="_blank"
                                                >
                                                    {
                                                        `${pool?.tokenCurrentChain?.substring(0, 10)}...`
                                                    }

                                                </a>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-800 dark:text-neutral-200 ">
                                            <div className="flex">
                                                <Image
                                                    priority
                                                    src={addressesToIcons[pool?.tokenCurrentChain! as allowedTokens]}
                                                    alt="deposit"
                                                    width={20}
                                                    height={20}
                                                    className="mr-4"
                                                />
                                                <a className="text-blue-600 hover:text-blue-800 hover:bg-blue-100 px-2 py-1 rounded"
                                                    href={`${CCIP_EXPLORER_URL_ADDRESS}${pool?.tokenCrossChain}`}
                                                    target="_blank"
                                                >
                                                    {
                                                        `${pool?.tokenCrossChain?.substring(0, 25
                                                        )}...`
                                                    }
                                                </a>
                                            </div>
                                        </td>

                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-800 dark:text-neutral-200 ">
                                            <div className="flex">
                                                <Image
                                                    priority
                                                    src={selectorsToIcons[pool?.crosschainSelector!.toString() as allowedChainSelectors]}
                                                    alt="deposit"
                                                    width={20}
                                                    height={20}
                                                    className="mr-4"
                                                />
                                                {
                                                    ccipSelectorsTochain[pool?.crosschainSelector!.toString() as allowedChainSelectors]
                                                }
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-end text-sm font-medium">
                                            <button type="button" className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-slate-300 dark:hover:bg-neutral-800disabled:opacity-50"
                                                data-hs-overlay="#deposit-modal"
                                                onClick={() => openModal(pool?.pool, pool.tokenCurrentChain, pool.tokenCrossChain)}
                                            >
                                                Deposit
                                            </button>
                                        </td>
                                    </tr>)
                                }


                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <DepositModal poolAddress={pool} currentChainTokenAddress={currentChainToken} poolName="Test Pool" crossChainTokenAddress={crossChainToken} />
        </div>
    )
}