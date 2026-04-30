"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const links = [
  { href: "/", label: "Dashboard" },
  { href: "/technicians", label: "Technicians" },
  { href: "/users", label: "Users" },
  { href: "/payouts", label: "Payouts" },
  { href: "/analytics", label: "Analytics" },
];

export default function AdminNav() {
  const pathname = usePathname();
  return (
    <nav className="sticky top-0 z-50 border-b border-slate-200 bg-white/90 backdrop-blur">
      <div className="mx-auto flex max-w-7xl items-center gap-1 px-4 py-2">
        <span className="mr-4 text-sm font-bold text-sky-700 tracking-wide">FixMate Admin</span>
        {links.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            className={`rounded-lg px-3 py-1.5 text-sm font-medium transition ${
              pathname === link.href
                ? "bg-slate-900 text-white"
                : "text-slate-600 hover:bg-slate-100"
            }`}
          >
            {link.label}
          </Link>
        ))}
      </div>
    </nav>
  );
}
