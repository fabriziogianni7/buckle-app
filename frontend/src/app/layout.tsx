import type { Metadata } from "next";
import { Inter } from "next/font/google";
import PrelineScript from "./config/Preline";
import "./globals.css";
import '@rainbow-me/rainbowkit/styles.css';
import Navbar from "@/app/components/common/Navbar";
import Providers from "./Providers";
import { headers } from "next/headers";


const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Buckle App",
  description: "Pool Crosschain Bridge Protocol",
};


export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const cookie = headers().get("cookie");
  return (
    <html lang="en">
      <PrelineScript />
      <Providers cookie={cookie}>
        <body className={inter.className}>
          <Navbar />
          <div className="container mx-auto ">
            {children}
          </div>
        </body>
      </Providers>
    </html>

  );
}
