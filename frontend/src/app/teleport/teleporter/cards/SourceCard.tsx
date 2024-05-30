'use client'

import { Dispatch, SetStateAction } from "react";
import useCurrentChainSelector from "@/app/hooks/useCurrentChainSelector";
import { Pool } from "@/app/config/interfaces";
import CustomInput from "@/app/components/common/CustomInput";
import Image from 'next/image';
import { addressesToIcons, addressesToNames, allowedTokens } from "@/app/config/generalConfig";


interface CardProps {
    title: string
    subtitle: string
    poolsAndTokens: Pool[] | undefined
    selectedToken: `0x${string}` | undefined
    setTokenToBridge: Dispatch<SetStateAction<`0x${string}` | undefined>>
    setAmountToBridge: (val: number) => void,
}

// i want to chose the network
// i want to chose the token



export default function SourceCard({ title = "title", subtitle = "subtitle", poolsAndTokens, selectedToken, setTokenToBridge, setAmountToBridge }: CardProps) {
    const { selector: currentSelector } = useCurrentChainSelector()
    return (
        <div className="col-span-4">
            <div className="flex flex-col bg-white border shadow-sm rounded-xl dark:bg-neutral-900 dark:border-neutral-700 dark:shadow-neutral-700/70 w-80" >
                <div className="p-4 md:p-10">
                    <h3 className="text-lg font-bold text-gray-800 dark:text-slate-300">
                        <div className="flex">
                            <Image
                                priority
                                src={"/icons-buckle/half-left-teleport-icon-white.svg"}
                                alt="deposit"
                                width={30}
                                height={30}
                                className="mr-2"
                            />
                            {title}
                        </div>
                    </h3>
                    <p className="mt-2 text-gray-500 dark:text-neutral-400">
                        {subtitle}
                    </p>
                    <br />
                    {/* for selecting chain */}
                    <select className="py-3 px-4 pe-9 block w-full border-gray-200 rounded-lg text-sm focus:border-blue-500 focus:ring-blue-500 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-neutral-400 dark:placeholder-neutral-500 dark:focus:ring-neutral-600"
                        onChange={(e) => setTokenToBridge(e.target.value as `0x${string}`)}>
                        <option key={0} value={undefined}>Select Token To Bridge</option>
                        {
                            poolsAndTokens?.map((el, i) =>
                                <option key={i + 1}
                                    value={el.tokenCurrentChain}
                                    style={{ background: `url(http://localhost:3000/${addressesToIcons[el?.tokenCurrentChain! as allowedTokens]})`, width: 10 }}
                                >
                                    {addressesToNames[el?.tokenCurrentChain! as allowedTokens]} | {
                                        `${el?.tokenCurrentChain?.substring(0, 10)}...`
                                    }
                                </option>


                            )
                        }
                    </select>
                    <br />
                    <hr></hr>
                    <br />
                    {
                        <CustomInput title="Set Amount" setValue={setAmountToBridge} disabled={selectedToken == undefined} />
                    }
                </div>
            </div>
        </div>
    )
}