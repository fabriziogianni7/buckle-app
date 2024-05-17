'use client'

import { HSOverlay, ICollectionItem } from "preline/preline";
import { Dispatch, SetStateAction, useState } from "react";
import { allTokens, ccipSelectorsTochain } from "@/app/config/generalConfig";
import useCurrentChainSelector from "@/app/hooks/useCurrentChainSelector";


interface CardProps {
    title: string
    subtitle: string
    setDestinationSelector: Dispatch<SetStateAction<string | undefined>>
}




export default function DestinationCard({ title = "title", subtitle = "subtitle", setDestinationSelector }: CardProps) {
    const { selector: currentSelector } = useCurrentChainSelector()
    return (
        <div className="col-span-4">
            <div className="flex flex-col bg-white border shadow-sm rounded-xl dark:bg-neutral-900 dark:border-neutral-700 dark:shadow-neutral-700/70">
                <div className="p-4 md:p-10">
                    <h3 className="text-lg font-bold text-gray-800 dark:text-white">
                        {title}
                    </h3>
                    <p className="mt-2 text-gray-500 dark:text-neutral-400">
                        {subtitle}
                    </p>
                    <select className="py-3 px-4 pe-9 block w-full border-gray-200 rounded-lg text-sm focus:border-blue-500 focus:ring-blue-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-neutral-400 dark:placeholder-neutral-500 dark:focus:ring-neutral-600"
                        onChange={(e) => {
                            setDestinationSelector(e.target.value)
                        }

                        }
                    >
                        <option key={0} defaultValue={"0"}>Select Destination Network</option>
                        {
                            Object.entries(ccipSelectorsTochain)
                                .filter((el) => el[0] != currentSelector)
                                .map((el, i) => <option key={i + 1} value={el[0]} >{el[1]}</option>)
                        }
                    </select>
                </div>
            </div>
        </div>
    )
}