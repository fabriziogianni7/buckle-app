import type { Metadata } from "next";
import { Inter } from "next/font/google";
import PrelineScript from "./config/Preline";
import "./globals.css";
import '@rainbow-me/rainbowkit/styles.css';
import Navbar from "@/app/components/common/Navbar";
import Providers from "./Providers";
import { headers } from "next/headers";
import Footer from "./components/common/Footer";


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
      <body className={`${inter.className} bg-repeat`}
        style={{
          backgroundImage: "url('/floreal-background.svg')",
        }}>
        <PrelineScript />
        <Providers cookie={cookie}>
          <Navbar />
          <div className="container mx-auto bg-gradient-to-b from-neutral-900 to-transparent"
          >
            {children}
          </div>
          <Footer />
        </Providers>
        {/* <script src="node_modules/preline/dist/preline.js"></script> */}
      </body>
    </html >

  );
}
