"use client";

import { useState } from "react";
import type { RunResult, TrendingState } from "@/lib/trending";

export function TrendingAutopilot({ initial }: { initial: TrendingState }) {
  const [state, setState] = useState(initial);
  const [preview, setPreview] = useState<RunResult | null>(null);
  const [busy, setBusy] = useState<"toggle" | "preview" | null>(null);
  const [error, setError] = useState("");

  async function call(action: "enable" | "disable" | "preview") {
    setBusy(action === "preview" ? "preview" : "toggle");
    setError("");
    try {
      const res = await fetch("/api/push/trending", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error ?? "Request failed.");
      if (action === "preview") setPreview(json);
      else setState(json);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Request failed.");
    } finally {
      setBusy(null);
    }
  }

  const toggle = () => {
    if (!state.enabled && !confirm("Turn on the trending autopilot? It will send one push to ALL users on days a cafe is trending.")) return;
    call(state.enabled ? "disable" : "enable");
  };

  return (
    <section className="panel panel-pad stack tight">
      <div className="row between">
        <div>
          <p className="eyebrow">Trending autopilot</p>
          <p className="muted small">
            Daily at 18:30 IST: finds the cafe whose distinct viewers today beat its own weekly average (at least 4 players,
            1.5× usual), has Claude write the push and sends it to all users. At most one a day, never 22:00–09:00 IST, and
            the same cafe at most once a week. Taps open Home, since cafes have no deep link yet.
          </p>
        </div>
        <span className="pill">{state.enabled ? "On" : "Off"}</span>
      </div>
      <p className="muted small">
        Last run: {state.lastRunAt ? new Date(state.lastRunAt).toLocaleString("en-IN") : "never"}
        {state.lastOutcome && ` · ${state.lastOutcome}`}
      </p>
      <div className="row">
        <button className={state.enabled ? "button-secondary" : "button"} onClick={toggle} disabled={busy !== null}>
          {busy === "toggle" ? "Saving…" : state.enabled ? "Pause autopilot" : "Turn on autopilot"}
        </button>
        <button className="button-secondary" onClick={() => call("preview")} disabled={busy !== null}>
          {busy === "preview" ? "Checking trends…" : "Preview today's trend"}
        </button>
      </div>
      {error && <p className="error">{error}</p>}
      {preview?.outcome === "skipped" && <p className="muted small">{preview.reason}</p>}
      {preview?.outcome === "preview" && (
        <div className="stack tight">
          <p className="muted small">
            {preview.trend.cafeName}: {preview.trend.viewersToday} players today vs {preview.trend.dailyAverage.toFixed(1)}/day
            usual ({preview.trend.lift.toFixed(1)}×). Copy by {preview.copySource === "ai" ? "Claude" : "fallback template"}.
            Nothing was sent.
          </p>
          <div className="notif">
            <div className="notif-head">
              <span className="app-dot" /> Hash · now
            </div>
            <strong>{preview.title}</strong>
            <p>{preview.body}</p>
          </div>
        </div>
      )}
    </section>
  );
}
