import { crossChainPoolAbi } from "@/app/abis/crossChainPoolAbi";
import { ierc20Abi } from "@/app/abis/ierc20Abi";
import CustomInput from "@/app/components/common/CustomInput";
import { useEffect, useState } from "react";
import { formatEther } from "viem";
import { useAccount, useContractRead, useReadContract, useWaitForTransactionReceipt, useWriteContract } from "wagmi";
import Image from 'next/image';
// import * as depositIcon from "/icons-buckle/deposit-icon-withe.svg";


interface DepositModalProps {
    poolName: string,
    poolAddress: `0x${string}` | undefined,
    currentChainTokenAddress: `0x${string}` | undefined,
    crossChainTokenAddress: `0x${string}` | undefined
}

export default function DepositModal({
    poolName = "test",
    poolAddress = "0x",
    currentChainTokenAddress = "0x",
    crossChainTokenAddress = "0x"
}: DepositModalProps) {
    // approve the pool to spend the token write
    // forecast the fees to pay to ccip read
    // call deposit write
    const [amount, setAmount] = useState<number>()
    const [phase, setPhase] = useState<"approve" | "deposit" | "success">()
    const { writeContract, error, context, data: hash, status, isPending } = useWriteContract()
    const { address } = useAccount()

    const resetState = () => {
        setPhase(undefined)
        setAmount(0)
    }

    const { data: allowance } = useReadContract({
        abi: ierc20Abi,
        address: currentChainTokenAddress,
        functionName: "allowance",
        args: [
            address,
            poolAddress
        ]
    })

    const { data: ccipFees } = useReadContract({
        abi: crossChainPoolAbi,
        address: poolAddress,
        functionName: "getCCipFeesForDeposit",
        args: [
            amount
        ]
    })

    const { data: lptInExchangeOfUnderlying } = useReadContract({
        abi: crossChainPoolAbi,
        address: poolAddress,
        functionName: "calculateLPTinExchangeOfUnderlying",
        args: [
            amount
        ]
    })

    const { data: symbol } = useReadContract({
        abi: crossChainPoolAbi,
        address: poolAddress,
        functionName: "symbol",
    })

    const { isLoading: isConfirming, isSuccess: isConfirmed } =
        useWaitForTransactionReceipt({
            hash,
        })



    const approve = () => {
        const abi = ierc20Abi
        if (poolAddress) {
            writeContract({
                abi,
                address: currentChainTokenAddress,
                functionName: "approve",
                args: [ //IERC20 _token, uint256 _amount
                    poolAddress,
                    amount
                ]
            })
            setPhase("approve")
        }
    }

    const deposit = () => {
        const abi = crossChainPoolAbi
        if (poolAddress && ccipFees) {
            writeContract({
                abi,
                address: poolAddress,
                functionName: "deposit",
                args: [ //IERC20 _token, uint256 _amount
                    currentChainTokenAddress,
                    amount
                ],
                value: ccipFees as bigint
            })
            setPhase("deposit")
        }
    }

    useEffect(() => {
        if (phase == "approve" && isConfirmed) {
            alert("you succesfully approved the tokens, please sign the next transaction to deposit")
            deposit()
        }
        if (phase == "deposit" && isConfirmed) {
            setPhase("success")
        }
    }, [hash, isConfirming, isConfirmed])



    const methodNeeded = () => {
        if (amount && allowance as number >= amount)
            return deposit()
        return approve()
    }

    const setCorrectAmountToDeposit = (amount: number) => {
        const finalValue = amount * 1e18
        setAmount(finalValue)
    }





    return (<div id="deposit-modal" className="hs-overlay hidden size-full fixed top-0 start-0 z-[80] overflow-x-hidden overflow-y-auto pointer-events-none">
        {
            (phase == "approve" || phase == "deposit") && isConfirming &&
            < div className="mt-2 bg-yellow-100 border border-yellow-200 text-sm text-yellow-800 rounded-lg p-4 dark:bg-yellow-800/10 dark:border-yellow-900 dark:text-yellow-500" role="alert">
                <span className="font-bold">Wait for tx to land onchain</span> Wait a minute till the tx land onchain
            </div>

        }
        <div className="hs-overlay-open:mt-7 hs-overlay-open:opacity-100 hs-overlay-open:duration-500 mt-0 opacity-0 ease-out transition-all sm:max-w-lg sm:w-full m-3 sm:mx-auto min-h-[calc(100%-3.5rem)] flex items-center">
            <div className="flex flex-col bg-white border shadow-sm rounded-xl pointer-events-auto dark:bg-neutral-800 dark:border-neutral-700 dark:shadow-neutral-700/70">
                <div className="flex justify-between items-center py-3 px-4 border-b dark:border-neutral-700">
                    <h3 className="font-bold text-gray-800 dark:text-slate-300">
                        Deposit Tokens In Buckle
                    </h3>
                    <button type="button" className="flex justify-center items-center size-7 text-sm font-semibold rounded-full border border-transparent text-gray-800 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none dark:text-slate-300 dark:hover:bg-neutral-700" data-hs-overlay="#deposit-modal">
                        <span className="sr-only">Close</span>
                        <svg className="flex-shrink-0 size-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                            <path d="M18 6 6 18"></path>
                            <path d="m6 6 12 12"></path>
                        </svg>
                    </button>
                </div>
                <div className="p-4 overflow-y-auto">
                    {
                        phase != "success" &&
                        <div className="max-w-xs bg-white border border-gray-200 rounded-xl shadow-lg dark:bg-neutral-800 dark:border-neutral-700" role="alert">
                            <div className="flex p-4">
                                <div className="flex-shrink-0">
                                    <Image
                                        priority
                                        src={"/icons-buckle/deposit-icon-withe.svg"}
                                        alt="deposit"
                                        width={40}
                                        height={40}
                                    />
                                </div>
                                <div className="ms-4">
                                    <h3 className="text-gray-800 font-semibold dark:text-slate-300">
                                        Deposit Tokens
                                    </h3>
                                    <div className="mt-1 text-sm text-gray-600 dark:text-neutral-400">
                                        You&apos;re going to approve and deposit tokens into the {poolName} pool.
                                    </div>
                                    <div className="mt-4">
                                        <div className="flex flex-col space-y-3">

                                            <span className="inline-flex items-center gap-x-1.5 py-1.5 px-3 rounded-full text-xs font-medium border border-gray-800 text-gray-800 border-yellow-500
                                            dark:border-yellow-500 dark:text-slate-300">ccip fees: {ccipFees as bigint ? formatEther(ccipFees as bigint).substring(0, 15) : 0} ETH</span>
                                            <span className="inline-flex items-center gap-x-1.5 py-1.5 px-3 rounded-full text-xs font-medium bg-teal-100 text-teal-800 dark:bg-teal-800/30 dark:text-teal-500">You get:    {lptInExchangeOfUnderlying as bigint ? formatEther(lptInExchangeOfUnderlying as bigint).substring(0, 15) : 0} {symbol as string} </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    }
                    {
                        phase == "success" &&
                        <div className="max-w-xs bg-white border border-gray-200 rounded-xl shadow-lg dark:bg-neutral-800 dark:border-neutral-700 text-wrap" role="alert">
                            <div className="flex p-4 text-wrap">
                                <div className="flex-shrink-0">
                                    <svg className="flex-shrink-0 size-4 text-teal-500 mt-0.5" xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                                        <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zm-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"></path>
                                    </svg>
                                </div>
                                <div className="ms-3 max-w-30">
                                    <article className="text-sm text-pretty break-all  text-gray-700 dark:text-neutral-400">
                                        <h3>You successfully deposited into the pool.</h3>
                                        <p className="text-sm text-blue-200 hover:text-green-200"><a href={`https://ccip.chain.link/tx/${hash}`} target="_blank">
                                            {hash}
                                        </a>
                                        </p>
                                    </article>
                                </div>
                            </div>
                        </div>
                    }

                    <br />
                    <hr></hr>
                    <br />
                    <CustomInput disabled={false} title="Select Amount of Tokens you want to deposit" setValue={setCorrectAmountToDeposit} />
                </div>
                <div className="flex justify-end items-center gap-x-2 py-3 px-4 border-t dark:border-neutral-700">
                    <button type="button" className="py-2 px-3 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-slate-300 dark:hover:bg-neutral-800" data-hs-overlay="#deposit-modal"
                        onClick={() => resetState()}>
                        Close
                    </button>
                    < button type="button" disabled={isConfirming} className="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-teal-500 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:hover:bg-neutral-800"
                        onClick={() => methodNeeded()}>
                        {phase == "approve" && !isConfirming ? "Approve" : "Deposit"}
                        {isConfirming && <div className="animate-spin inline-block size-6 border-[3px] border-current border-t-transparent text-red-600 rounded-full" role="status" aria-label="loading">
                            <span className="sr-only">Wait For Transaction</span>
                        </div>}
                    </button>
                </div>
            </div>
        </div>
    </div >
    );
}