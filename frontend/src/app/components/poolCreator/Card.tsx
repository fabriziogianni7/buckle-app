'use client'

import { allowedChainids } from "@/app/config/generalConfig";
import { Dispatch, SetStateAction } from "react";

interface CardProps {
    title: string,
    SourceOrDestination: "Source" | "Destination",
    setDestinationNetwork: Dispatch<SetStateAction<allowedChainids | undefined>>
    setToken: Dispatch<SetStateAction<"usdc" | undefined>>
    createPoolPairs: () => void;


}
export default function Card({
    title,
    SourceOrDestination,
    setDestinationNetwork,
    setToken,
    createPoolPairs
}: CardProps) {
    return (
        <div className="flex flex-col bg-white border shadow-sm  dark:bg-neutral-900 dark:border-neutral-700 dark:shadow-neutral-700/70">
            <div className="p-4 md:p-5">
                <h3 className="text-lg font-bold text-gray-800 dark:text-white">
                    Select Destination Network
                </h3>
                <div>
                    <select className=" border-gray-200 rounded-lg text-sm focus:border-blue-500 focus:ring-blue-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-neutral-400 dark:placeholder-neutral-500 dark:focus:ring-neutral-600"
                        onChange={(e) => setDestinationNetwork(Number(e.target.value) as allowedChainids)}

                    >
                        <option defaultValue={"Sepolia"}>Select Destination Network</option>
                        {/* todo add logos */}
                        <option value="11155111">Sepolia</option>
                        <option value="421614">Arbitrum</option>
                    </select>
                </div>
            </div>
            <div className="p-4 md:p-5">
                <h3 className="text-lg font-bold text-gray-800 dark:text-white">
                    Select Tokens
                </h3>
                <div>
                    <select className=" border-gray-200 rounded-lg text-sm focus:border-blue-500 focus:ring-blue-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-neutral-400 dark:placeholder-neutral-500 dark:focus:ring-neutral-600"
                        onChange={(e) => setToken(e.target.value as "usdc")}
                    >
                        <option defaultValue={"Sepolia"}>Select Tokens</option>
                        {/* todo add logos */}
                        <option value="usdc">USDC</option>
                    </select>
                </div>
            </div>
            <div className="bg-gray-100 border-t rounded-b-xl py-3 px-4 md:py-4 md:px-5 dark:bg-neutral-900 dark:border-neutral-700">
                <button type="button" className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent text-yellow-500 hover:bg-yellow-100 hover:text-yellow-800 disabled:opacity-50 disabled:pointer-events-none dark:hover:bg-yellow-800/30 dark:hover:text-yellow-400"
                    onClick={() => createPoolPairs()}>
                    Deploy Pools Cross Chain
                </button>
            </div>
        </div>
    );
}