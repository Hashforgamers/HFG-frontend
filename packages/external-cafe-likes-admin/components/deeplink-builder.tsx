"use client";

import { useState } from "react";
import { DESTINATIONS, buildLink, inspectLink, missingParams, type Utm } from "@/lib/deeplinks";

export type LinkState = { destKey: string; values: Record<string, string>; utm: Utm };

export const emptyLink: LinkState = { destKey: "", values: {}, utm: { source: "push", medium: "push" } };

const groups = [...new Set(DESTINATIONS.map((d) => d.group))];

export function resolveLink(state: LinkState) {
  const dest = DESTINATIONS.find((d) => d.key === state.destKey);
  if (!dest) return null;
  const missing = missingParams(dest, state.values);
  return { dest, missing, built: missing.length ? null : buildLink(dest, state.values, state.utm) };
}

function Copy({ text }: { text: string }) {
  const [done, setDone] = useState(false);
  return (
    <button
      type="button"
      className="button-ghost small"
      onClick={() => navigator.clipboard.writeText(text).then(() => (setDone(true), setTimeout(() => setDone(false), 1200)))}
    >
      {done ? "Copied" : "Copy"}
    </button>
  );
}

export function DeeplinkBuilder({ value, onChange }: { value: LinkState; onChange: (next: LinkState) => void }) {
  const [paste, setPaste] = useState("");
  const [pasteError, setPasteError] = useState("");
  const resolved = resolveLink(value);
  const set = (patch: Partial<LinkState>) => onChange({ ...value, ...patch });

  function inspect() {
    const found = inspectLink(paste);
    if (!found) return setPasteError("Not a link the app understands.");
    setPasteError("");
    const url = paste.startsWith("/") ? null : new URL(paste.trim());
    const utm: Utm = { ...value.utm };
    for (const k of ["source", "medium", "campaign", "content"] as const) {
      const v = url?.searchParams.get(`utm_${k}`);
      if (v) utm[k] = v;
    }
    onChange({ destKey: found.dest.key, values: found.values, utm });
  }

  return (
    <div className="stack tight">
      <label className="field">
        <span className="label">Destination</span>
        <select className="input" value={value.destKey} onChange={(e) => set({ destKey: e.target.value, values: {} })}>
          <option value="">No link (just open the app)</option>
          {groups.map((g) => (
            <optgroup key={g} label={g}>
              {DESTINATIONS.filter((d) => d.group === g).map((d) => (
                <option key={d.key} value={d.key}>
                  {d.label}
                  {d.opens ? "" : " (lands on Home)"}
                </option>
              ))}
            </optgroup>
          ))}
        </select>
      </label>

      {resolved && <p className={resolved.dest.opens ? "muted small" : "warn small"}>{resolved.dest.hint}</p>}

      {resolved?.dest.params.map((p) => (
        <label key={p.key} className="field">
          <span className="label">{p.label}</span>
          <input
            className="input"
            placeholder={p.placeholder}
            value={value.values[p.key] ?? ""}
            onChange={(e) => set({ values: { ...value.values, [p.key]: e.target.value } })}
          />
        </label>
      ))}

      {resolved && resolved.built?.kind !== "route" && (
        <div className="row">
          {(["source", "medium", "campaign"] as const).map((k) => (
            <label key={k} className="field">
              <span className="label">utm_{k}</span>
              <input className="input" value={value.utm[k] ?? ""} onChange={(e) => set({ utm: { ...value.utm, [k]: e.target.value } })} />
            </label>
          ))}
        </div>
      )}

      {resolved?.built && (
        <div className="stack tight">
          <div className="link-out">
            <span className="pill">{resolved.built.kind}</span>
            <code>{resolved.built.value}</code>
            <Copy text={resolved.built.value} />
          </div>
          {resolved.built.web && (
            <div className="link-out">
              <span className="pill">share</span>
              <code>{resolved.built.web}</code>
              <Copy text={resolved.built.web} />
            </div>
          )}
        </div>
      )}
      {resolved && resolved.missing.length > 0 && <p className="warn small">Fill in: {resolved.missing.join(", ")}</p>}

      <details>
        <summary className="muted small">Paste an existing link to check it</summary>
        <div className="row" style={{ marginTop: 10 }}>
          <input className="input" placeholder="hash://shop/product/123 or https://www.hashforgamers.com/…" value={paste} onChange={(e) => setPaste(e.target.value)} />
          <button type="button" className="button-secondary" onClick={inspect}>
            Check
          </button>
        </div>
        {pasteError && <p className="error">{pasteError}</p>}
      </details>
    </div>
  );
}
