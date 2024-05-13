'use client'
import { ConnectButton } from "@rainbow-me/rainbowkit";
import PoolCreator from "./components/poolCreator/PoolCreator";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <PoolCreator />
    </main>
  );
}
