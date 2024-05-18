
'use client'

import { usePathname } from "next/navigation";
import { WagmiConnectButton } from "./WagmiConnectButton";
import Image from 'next/image';


export default function Navbar() {
    const pathname = usePathname()
    return (
        <header className="flex flex-wrap sm:justify-start sm:flex-nowrap w-full bg-white text-sm py-4 dark:bg-neutral-800">
            <nav className="max-w-[85rem] w-full mx-auto px-4 sm:flex sm:items-center sm:justify-between" aria-label="Global">
                <div className="flex items-center justify-between">
                    <a className="inline-flex items-center gap-x-2 text-xl font-semibold dark:text-slate-300" href="#">
                        <Image
                            priority
                            src={"/icons-buckle/teleport-icon-white.svg"}
                            alt="deposit"
                            width={70}
                            height={70}
                        />
                        Buckle
                    </a>
                    <div className="sm:hidden">
                        <button type="button" className="hs-collapse-toggle p-2 inline-flex justify-center items-center gap-x-2 rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-transparent dark:border-neutral-700 dark:text-slate-300 dark:hover:bg-white/10" data-hs-collapse="#navbar-image-and-text-1" aria-controls="navbar-image-and-text-1" aria-label="Toggle navigation">
                            <svg className="hs-collapse-open:hidden flex-shrink-0 size-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="3" x2="21" y1="6" y2="6" /><line x1="3" x2="21" y1="12" y2="12" /><line x1="3" x2="21" y1="18" y2="18" /></svg>
                            <svg className="hs-collapse-open:block hidden flex-shrink-0 size-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18" /><path d="m6 6 12 12" /></svg>
                        </button>
                    </div>
                </div>
                <div id="navbar-image-and-text-1" className="hs-collapse hidden overflow-hidden transition-all duration-300 basis-full grow sm:block">
                    <div className="flex flex-col gap-5 mt-5 sm:flex-row sm:items-center sm:justify-end sm:mt-0 sm:ps-5">
                        <a className={
                            pathname == "/" ? "font-medium text-blue-500 hover:text-gray-400" : "text-gray-600 hover:text-gray-400 dark:text-neutral-400 dark:hover:text-neutral-500"
                        } href="/" aria-current="page">Home</a>
                        <a className={
                            pathname == "/stake" ? "font-medium text-blue-500 hover:text-gray-400" : "text-gray-600 hover:text-gray-400 dark:text-neutral-400 dark:hover:text-neutral-500"
                        } href="stake">Stake</a>
                        <a className={
                            pathname == "/teleport" ? "font-medium text-blue-500 hover:text-gray-400" : "text-gray-600 hover:text-gray-400 dark:text-neutral-400 dark:hover:text-neutral-500"
                        } href="teleport">Teleport</a>
                        <a className={
                            pathname == "/redeem" ? "font-medium text-blue-500 hover:text-gray-400" : "text-gray-600 hover:text-gray-400 dark:text-neutral-400 dark:hover:text-neutral-500"
                        } href="redeem">Redeem</a>


                        <div>
                            <WagmiConnectButton />
                        </div>
                    </div>
                </div>
            </nav>
        </header>
    );
}