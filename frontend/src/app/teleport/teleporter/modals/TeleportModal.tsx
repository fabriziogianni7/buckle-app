import { crossChainPoolAbi } from "@/app/abis/crossChainPoolAbi";
import { ierc20Abi } from "@/app/abis/ierc20Abi";
import CustomInput from "@/app/components/common/CustomInput";
import { allowedChainSelectors, ccipSelectorsTochain } from "@/app/config/generalConfig";
import useCurrentChainSelector from "@/app/hooks/useCurrentChainSelector";
import { useEffect, useState } from "react";
import { formatEther } from "viem";
import { useAccount, useChainId, useReadContract, useWaitForTransactionReceipt, useWriteContract, type UseReadContractReturnType } from "wagmi";

interface TeleportModalProps {

    poolAddress: `0x${string}` | undefined
    chainSelector: string | undefined // destination
    tokenToBridge: `0x${string}` | undefined
    amountToBridge: number | undefined
}

export default function TeleportModal({
    poolAddress = "0x",
    chainSelector,
    tokenToBridge,
    amountToBridge
}: TeleportModalProps) {
    // approve the pool to spend the token write
    // forecast the fees to pay to ccip read
    // call deposit write
    const [phase, setPhase] = useState<"approve" | "teleport" | "success">()
    const { writeContract, error, context, data: hash, status, isPending } = useWriteContract()
    const { address: userAddress } = useAccount()
    const { selector: currentSelector, chainId: currentChainId, chainName: currentChainName } = useCurrentChainSelector()



    const { data: allowance } = useReadContract({
        abi: ierc20Abi,
        address: tokenToBridge,
        functionName: "allowance",
        args: [
            userAddress,
            poolAddress
        ]
    })

    const { data: ccipFees } = useReadContract({
        abi: crossChainPoolAbi,
        address: poolAddress,
        functionName: "getCCipFeesForDeposit",
        args: [
            amountToBridge
        ]
    })
    useEffect(() => console.log("ccipFees", ccipFees), [ccipFees])

    const { isLoading: isConfirming, isSuccess: isConfirmed } =
        useWaitForTransactionReceipt({
            hash,
        })



    const approve = () => {
        const abi = ierc20Abi
        if (poolAddress) {
            writeContract({
                abi,
                address: tokenToBridge as `0x${string}`,
                functionName: "approve",
                args: [ //IERC20 _token, uint256 _amount
                    poolAddress,
                    amountToBridge
                ]
            })
            setPhase("approve")
        }
    }

    const teleport = () => {
        const abi = crossChainPoolAbi
        if (poolAddress && ccipFees) {
            writeContract({
                abi,
                address: poolAddress,
                functionName: "teleport",
                args: [
                    amountToBridge,
                    userAddress // this can change eventually
                ],
                value: ccipFees as bigint
            })
            setPhase("teleport")
        }
    }

    useEffect(() => {
        if (phase == "approve" && isConfirming) {
            alert("wait while the approve tx goes tru")
        }
        if (phase == "approve" && isConfirmed) {
            alert("you succesfully approved the tokens, please sign the next transaction to deposit")
            teleport()
        }
        if (phase == "teleport" && isConfirming) {
            alert("wait while the deposit tx goes tru")
        }
        if (phase == "teleport" && isConfirmed) {
            alert("The deposit was successful! yay")
            setPhase("success")
        }
    }, [hash, isConfirming, isConfirmed])



    const methodNeeded = () => {
        if (amountToBridge && allowance as number >= amountToBridge)
            return teleport()
        return approve()
    }



    return (
        <div id="teleport-modal" className="hs-overlay hidden size-full fixed top-0 start-0 z-[80] overflow-x-hidden overflow-y-auto pointer-events-none">
            <div className="hs-overlay-open:mt-7 hs-overlay-open:opacity-100 hs-overlay-open:duration-500 mt-0 opacity-0 ease-out transition-all sm:max-w-lg sm:w-full m-3 sm:mx-auto min-h-[calc(100%-3.5rem)] flex items-center">
                <div className="flex flex-col bg-white border shadow-sm rounded-xl pointer-events-auto dark:bg-neutral-800 dark:border-neutral-700 dark:shadow-neutral-700/70">
                    <div className="flex justify-between items-center py-3 px-4 border-b dark:border-neutral-700">
                        <h3 className="font-bold text-gray-800 dark:text-white">
                            Teleport Tokens from {currentChainName} to {ccipSelectorsTochain[chainSelector as allowedChainSelectors]}
                        </h3>
                        <button type="button" className="flex justify-center items-center size-7 text-sm font-semibold rounded-full border border-transparent text-gray-800 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none dark:text-white dark:hover:bg-neutral-700" data-hs-overlay="#teleport-modal">
                            <span className="sr-only">Close</span>
                            <svg className="flex-shrink-0 size-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <path d="M18 6 6 18"></path>
                                <path d="m6 6 12 12"></path>
                            </svg>
                        </button>
                    </div>
                    <div className="p-4 overflow-y-auto">
                        <div>
                            < p className="mt-1 text-gray-800 dark:text-neutral-400">
                                You're going to approve and "teleport" tokens from  {currentChainName} to {ccipSelectorsTochain[chainSelector as allowedChainSelectors]}.
                            </p>
                            <p className="mt-1 text-gray-800 dark:text-neutral-400">
                                You need to pay some {ccipFees as bigint ? formatEther(ccipFees as bigint) : 0} fees to ccip:
                            </p>
                            <p className="mt-1 text-gray-800 dark:text-neutral-400">
                                You'll receive this 122 on the other chain
                            </p>
                        </div>
                    </div >
                    <div className="flex justify-end items-center gap-x-2 py-3 px-4 border-t dark:border-neutral-700">
                        <button type="button" className="py-2 px-3 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-900 dark:border-neutral-700 dark:text-white dark:hover:bg-neutral-800" data-hs-overlay="#teleport-modal">
                            Close
                        </button>
                        < button type="button" disabled={false} className="py-2 px-3 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:pointer-events-none"
                            onClick={() => methodNeeded()}
                        >
                            {phase == "approve" && !isConfirming ? "Approve" : "Deposit"}
                            {isConfirming && <div className="animate-spin inline-block size-6 border-[3px] border-current border-t-transparent text-red-600 rounded-full" role="status" aria-label="loading">
                                <span className="sr-only">Wait For Transaction</span>
                            </div>}
                            Teleport ⚡️
                        </button>

                    </div>
                </div >
            </div >
        </div >
    );
}