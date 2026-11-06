"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

export function FlagSwitch({ flagKey, label, platform, platformLabel, enabled, warning }: {
  flagKey: string;
  label: string;
  platform: string;
  platformLabel: string;
  enabled: boolean;
  warning?: string;
}) {
  const router = useRouter();
  const [on, setOn] = useState(enabled);
  const [busy, setBusy] = useState(false);

  async function toggle() {
    const next = !on;
    const prompt = next
      ? `Turn ON ${label} for every ${platformLabel} user?${warning ? `\n\n${warning}` : ""}\n\nUsers get it the next time they open the app.`
      : `Turn OFF ${label} for every ${platformLabel} user?\n\nIt disappears the next time they open the app.`;
    if (!window.confirm(prompt)) return;
    setBusy(true);
    const res = await fetch("/api/push/flags", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ key: flagKey, platform, enabled: next }),
    });
    if (res.ok) setOn(next);
    else window.alert((await res.json()).error ?? "Update failed.");
    setBusy(false);
    router.refresh();
  }

  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      aria-label={`${label} on ${platformLabel}: ${on ? "on" : "off"}`}
      disabled={busy}
      onClick={toggle}
      className={`flag-switch${on ? " on" : ""}`}
    >
      <span className="flag-knob" />
      <span className="flag-text">{platformLabel}: {busy ? "Saving…" : on ? "On" : "Off"}</span>
    </button>
  );
}
