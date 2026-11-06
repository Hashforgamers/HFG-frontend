import Link from "next/link";
import type { ReactNode } from "react";
import { SignOutButton } from "@/components/sign-out-button";

const TABS = [
  ["/push", "Compose"],
  ["/push/campaigns", "Campaigns"],
  ["/push/deeplinks", "Deep links"],
  ["/push/flags", "Feature flags"],
  ["/dashboard", "Cafe likes"],
] as const;

export function PushShell({ active, email, title, subtitle, children }: {
  active: string;
  email?: string;
  title: string;
  subtitle: string;
  children: ReactNode;
}) {
  return (
    <main className="shell">
      <div className="container stack">
        <header className="page-header">
          <div>
            <p className="eyebrow">Hash Push Studio</p>
            <h1 className="title">{title}</h1>
            <p className="subtitle">{subtitle}</p>
          </div>
          <div className="actions">
            {email && <span className="pill">{email}</span>}
            <SignOutButton />
          </div>
        </header>
        <nav className="tabs">
          {TABS.map(([href, label]) => (
            <Link key={href} href={href} className={href === active ? "on" : ""}>
              {label}
            </Link>
          ))}
        </nav>
        {children}
      </div>
    </main>
  );
}
