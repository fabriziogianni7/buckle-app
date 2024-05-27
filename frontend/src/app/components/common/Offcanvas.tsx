
'use client'

import { CCIP_EXPLORER_URL_ADDRESS, CCIP_EXPLORER_URL_TX } from "@/app/config/generalConfig";
import useCrossChainPool from "@/app/hooks/useCrossChainPool";
import useUserTransactions from "@/app/hooks/useUserTransactions";
import { useEffect } from "react";
import { formatEther } from "viem";



export default function Offcanvas() {
    const { userDeposits, userTeleports } = useUserTransactions()

    useEffect(() => console.log("userDeposits", userDeposits))

    return (<div id="hs-overlay-example" className="hs-overlay hs-overlay-open:translate-x-0 hidden -translate-x-full fixed top-0 start-0 transition-all duration-300 transform h-full max-w-xs w-full z-[80] bg-white border-e dark:bg-neutral-800 dark:border-neutral-700 overflow-y-auto" tabIndex={-1}>
        <div className="flex justify-between items-center py-3 px-4 border-b dark:border-neutral-700">
            <h3 className="font-bold text-gray-800 dark:text-white">
                User Transactions On Buckle
            </h3>
            <button type="button" className="flex justify-center items-center size-7 text-sm font-semibold rounded-full border border-transparent text-gray-800 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none dark:text-white dark:hover:bg-neutral-700 " data-hs-overlay="#hs-overlay-example">
                <span className="sr-only">Close modal</span>
                <svg className="flex-shrink-0 size-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" strokeLinejoin="round">
                    <path d="M18 6 6 18"></path>
                    <path d="m6 6 12 12"></path>
                </svg>
            </button>
        </div>
        <div className="p-4 ">
            <ul className="max-w-xs flex flex-col divide-y divide-gray-200 dark:divide-neutral-700">
                <div >
                    <h3 className="font-bold text-gray-800 dark:text-white">
                        Deposits
                    </h3>
                    <p className="mt-2">
                        <button type="button" className="hs-collapse-toggle inline-flex items-center gap-x-1 text-sm font-semibold rounded-lg border border-transparent text-blue-600 hover:text-blue-800 disabled:opacity-50 disabled:pointer-events-none dark:text-blue-500 dark:hover:text-blue-400" id="hs-show-hide-collapse" data-hs-collapse="#hs-show-hide-collapse-heading-deposits">
                            <span className="hs-collapse-open:hidden">Show More</span>
                            <span className="hs-collapse-open:block hidden">Show Less</span>
                            <svg className="hs-collapse-open:rotate-180 flex-shrink-0 size-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="m6 9 6 6 6-6"></path>
                            </svg>
                        </button>
                    </p>
                </div>
                <div id="hs-show-hide-collapse-heading-deposits" className="hs-collapse hidden w-full overflow-hidden transition-[height] duration-300" aria-labelledby="hs-show-hide-collapse">
                    {
                        userDeposits?.map(d => <li className="inline-flex items-center gap-x-2 py-3 text-sm font-medium text-gray-800 dark:text-white ">
                            <div >
                                <p>{formatEther(d.underlyingAmount)} UTK</p>
                                <a className="text-blue-600 hover:text-blue-800 hover:bg-blue-100 px-2 py-1 rounded"
                                    href={`${CCIP_EXPLORER_URL_TX}${d.txHash}`}
                                    target="_blank"
                                >
                                    {d.txHash.substring(0, 16)}...
                                </a>
                            </div>
                        </li>)
                    }
                </div>


                <br />
                <hr />



            </ul>
        </div>
         <div className="p-4 ">
            <ul className="max-w-xs flex flex-col divide-y divide-gray-200 dark:divide-neutral-700">
                <div >
                    <h3 className="font-bold text-gray-800 dark:text-white">
                        Teleports
                    </h3>
                    <p className="mt-2">
                        <button type="button" className="hs-collapse-toggle inline-flex items-center gap-x-1 text-sm font-semibold rounded-lg border border-transparent text-blue-600 hover:text-blue-800 disabled:opacity-50 disabled:pointer-events-none dark:text-blue-500 dark:hover:text-blue-400" id="hs-show-hide-collapse" data-hs-collapse="#hs-show-hide-collapse-heading-teleports">
                            <span className="hs-collapse-open:hidden">Show More</span>
                            <span className="hs-collapse-open:block hidden">Show Less</span>
                            <svg className="hs-collapse-open:rotate-180 flex-shrink-0 size-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="m6 9 6 6 6-6"></path>
                            </svg>
                        </button>
                    </p>
                </div>
                <div id="hs-show-hide-collapse-heading-teleports" className="hs-collapse hidden w-full overflow-hidden transition-[height] duration-300" aria-labelledby="hs-show-hide-collapse">
                    {
                        userTeleports?.map(t => <li className="inline-flex items-center gap-x-2 py-3 text-sm font-medium text-gray-800 dark:text-white ">
                            <div >
                                <p>{formatEther(t.value)} UTK</p>
                                <a className="text-blue-600 hover:text-blue-800 hover:bg-blue-100 px-2 py-1 rounded"
                                    href={`${CCIP_EXPLORER_URL_TX}${t.txHash}`}
                                    target="_blank"
                                >
                                    {t.txHash.substring(0, 16)}...
                                </a>
                            </div>
                        </li>)
                    }
                </div>


                <br />
                <hr />



            </ul>
        </div> 
    </div>
    );
}