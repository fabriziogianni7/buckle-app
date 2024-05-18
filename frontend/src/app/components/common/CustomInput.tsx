import { Dispatch, SetStateAction } from "react";
import { call } from "viem/actions";

interface InputProps {
    title: string,
    setValue?: (val: number) => void,
    disabled: boolean
}

export default function CustomInput({
    title,
    setValue,
    disabled
}: InputProps) {
    return (
        <div className="py-2 px-3 w-full bg-white border border-gray-200 rounded-lg dark:bg-neutral-900 dark:border-neutral-700">
            <div className="w-full flex justify-between items-center gap-x-3" data-hs-input-number="">
                <div>
                    <span className="block text-xs text-gray-500 dark:text-neutral-400">
                        {title}
                    </span>
                    {
                        setValue &&
                        <input className="p-0 bg-transparent border-0 text-gray-800 focus:ring-0 dark:text-slate-300 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none" type="number" disabled={disabled}
                            onChange={(e: any) => setValue(e.target.value)
                            } />
                    }

                </div>

                <div className="flex justify-end items-center gap-x-1.5">
                </div>
            </div>
        </div>
    );
}