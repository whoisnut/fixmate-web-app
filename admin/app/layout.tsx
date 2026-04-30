import type { Metadata } from "next";
import { Space_Grotesk, JetBrains_Mono } from "next/font/google";
import "./globals.css";
import AdminNav from "@/components/AdminNav";

const displaySans = Space_Grotesk({
  variable: "--font-display-sans",
  subsets: ["latin"],
});

const monoSans = JetBrains_Mono({
  variable: "--font-ui-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "FixMate Admin",
  description: "FixMate web admin panel for operations and service management",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${displaySans.variable} ${monoSans.variable} antialiased bg-slate-50`}>
        <AdminNav />
        <main>{children}</main>
      </body>
    </html>
  );
}
