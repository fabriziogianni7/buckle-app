'use client'
import { ConnectButton } from "@rainbow-me/rainbowkit";
import Image from 'next/image';

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      {/* <!-- ========== MAIN CONTENT ========== --> */}
      <main id="content" className="relative max-w-3xl px-4 sm:px-6 lg:px-8 flex flex-col justify-center sm:items-center mx-auto size-full">
        <div className="text-center py-8 px-4 sm:px-6 lg:px-8">

          <h1 className="text-2xl text-slate-300 sm:text-4xl">
            Teleport tokens to different chains with low fees
          </h1>
          <h1 className="text-small text-slate-300 sm:text-small">
            LPs deposit in cross-chain pools and earn fees on Teleports
          </h1>
          <h2 className="mt-1 sm:mt-3 text-4xl font-bold text-slate-300 sm:text-6xl">
            <div className="py-8 px-4 sm:px-6 lg:px-8 flex justify-center items-center">
              <Image
                priority
                src={"/icons-buckle/half-left-teleport-icon-white.svg"}
                alt="deposit"
                width={70}
                height={70}
                className="mr-2"
              />
              <span className="bg-clip-text bg-gradient-to-tr from-yellow-500 to-yellow-900 text-transparent">Buckle</span>
              <Image
                priority
                src={"/icons-buckle/half-right-teleport-icon-white.svg"}
                alt="deposit"
                width={70}
                height={70}
                className="ml-1"
              />
            </div>
          </h2>

          <form>
            <div className="mt-8 space-y-4">


              <div className="grid">
                <button type="submit" className="sm:p-4 py-3 px-4 inline-flex justify-center items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent bg-white/10 text-slate-300 hover:bg-white/20 disabled:opacity-50 disabled:pointer-events-none">
                  <a href="/teleport" aria-current="page">
                    Launch App
                  </a>
                  <Image
                    priority
                    src={"/icons-buckle/teleport-icon-white.svg"}
                    alt="launch"
                    width={40}
                    height={40}
                  />
                </button>
              </div>
            </div>
          </form>
        </div>
      </main >
      {/* <!-- ========== END MAIN CONTENT ========== --> */}

    </main >
  );
}
