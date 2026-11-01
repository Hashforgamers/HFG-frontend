"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { DeeplinkBuilder, emptyLink, resolveLink, type LinkState } from "@/components/deeplink-builder";
import type { AiVariant } from "@/lib/ai";

type AudienceKind = "all" | "user" | "topic" | "token";
const CHANNELS = [
  ["system_channel", "System alerts"],
  ["offer_channel", "Offers"],
  ["contest_channel", "Contests"],
  ["chat_channel", "Chat"],
] as const;
const AUDIENCE: Record<AudienceKind, { label: string; placeholder: string }> = {
  all: { label: "All users", placeholder: "" },
  user: { label: "One user (uid)", placeholder: "Firebase uid" },
  topic: { label: "FCM topic", placeholder: "topic name" },
  token: { label: "Test device (FCM token)", placeholder: "Paste the token from the app's debug log" },
};

function Counter({ value, max }: { value: string; max: number }) {
  return <span className={value.length > max ? "error small" : "muted small"}>{value.length}/{max}</span>;
}

export function PushComposer() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [imageUrl, setImageUrl] = useState("");
  const [channel, setChannel] = useState<(typeof CHANNELS)[number][0]>("system_channel");
  const [link, setLink] = useState<LinkState>(emptyLink);
  const [audience, setAudience] = useState<AudienceKind>("all");
  const [audienceValue, setAudienceValue] = useState("");
  const [testToken, setTestToken] = useState("");
  const [when, setWhen] = useState<"now" | "later">("now");
  const [sendAt, setSendAt] = useState("");
  const [status, setStatus] = useState<{ kind: "ok" | "error"; text: string } | null>(null);
  const [busy, setBusy] = useState(false);

  const [goal, setGoal] = useState("");
  const [aiAudience, setAiAudience] = useState("");
  const [tone, setTone] = useState("playful, confident");
  const [language, setLanguage] = useState<"English" | "Hinglish" | "Hindi">("Hinglish");
  const [count, setCount] = useState(4);
  const [variants, setVariants] = useState<AiVariant[]>([]);
  const [aiBusy, setAiBusy] = useState(false);
  const [aiError, setAiError] = useState("");

  const resolved = resolveLink(link);
  const payloadLink = resolved?.built ? { kind: resolved.built.kind, value: resolved.built.value } : undefined;

  async function generate(improve: boolean) {
    setAiBusy(true);
    setAiError("");
    try {
      const res = await fetch("/api/push/ai", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ goal, audience: aiAudience, tone, language, count, current: improve ? { title, body } : undefined }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error);
      setVariants(json.variants);
    } catch (e) {
      setAiError(e instanceof Error ? e.message : "AI request failed.");
    } finally {
      setAiBusy(false);
    }
  }

  function useVariant(v: AiVariant) {
    setTitle(v.title);
    setBody(v.body);
    setChannel(v.channel);
    setName((n) => n || v.utm_campaign);
    setLink({
      destKey: v.destination_key,
      values: Object.fromEntries(v.destination_params.map((p) => [p.key, p.value])),
      utm: { ...link.utm, campaign: v.utm_campaign },
    });
  }

  async function send(test: boolean) {
    const target = test ? { kind: "token" as const, value: testToken } : { kind: audience, value: audienceValue };
    if (resolved && !resolved.built) return setStatus({ kind: "error", text: `Deep link needs: ${resolved.missing.join(", ")}` });
    if (!test && audience === "all" && when === "now" && !window.confirm("Send this to ALL users right now?")) return;
    setBusy(true);
    setStatus(null);
    try {
      const res = await fetch("/api/push/send", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: test ? `[test] ${name || title}` : name,
          title,
          body,
          imageUrl: imageUrl.trim() || undefined,
          link: payloadLink,
          channel,
          audience: target,
          sendAt: !test && when === "later" && sendAt ? new Date(sendAt).toISOString() : undefined,
          test,
        }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error);
      setStatus({ kind: "ok", text: json.status === "scheduled" ? `Scheduled (${json.id}).` : `Sent (${json.id}).` });
      router.refresh();
    } catch (e) {
      setStatus({ kind: "error", text: e instanceof Error ? e.message : "Send failed." });
    } finally {
      setBusy(false);
    }
  }

  const data: Record<string, string> = { type: "campaign", campaign_id: "<assigned on send>", title, body };
  if (payloadLink) data[payloadLink.kind] = payloadLink.value;

  return (
    <div className="composer">
      <section className="stack">
        <div className="panel panel-pad stack tight">
          <div className="eyebrow">AI copywriter</div>
          <label className="field">
            <span className="label">What should this push achieve?</span>
            <textarea
              className="input"
              rows={3}
              placeholder="e.g. Bring back users who haven't played Ludo in 7 days. Weekend leaderboard resets Sunday night."
              value={goal}
              onChange={(e) => setGoal(e.target.value)}
            />
          </label>
          <div className="row">
            <label className="field">
              <span className="label">Who is it for</span>
              <input className="input" placeholder="lapsed Ludo players" value={aiAudience} onChange={(e) => setAiAudience(e.target.value)} />
            </label>
            <label className="field">
              <span className="label">Tone</span>
              <input className="input" value={tone} onChange={(e) => setTone(e.target.value)} />
            </label>
          </div>
          <div className="row">
            <label className="field">
              <span className="label">Language</span>
              <select className="input" value={language} onChange={(e) => setLanguage(e.target.value as typeof language)}>
                <option>Hinglish</option>
                <option>English</option>
                <option>Hindi</option>
              </select>
            </label>
            <label className="field">
              <span className="label">Variants</span>
              <select className="input" value={count} onChange={(e) => setCount(Number(e.target.value))}>
                {[2, 3, 4, 5, 6].map((n) => (
                  <option key={n}>{n}</option>
                ))}
              </select>
            </label>
          </div>
          <div className="actions">
            <button type="button" className="button" disabled={aiBusy || !goal.trim()} onClick={() => generate(false)}>
              {aiBusy ? "Writing…" : "Write variants"}
            </button>
            <button type="button" className="button-secondary" disabled={aiBusy || !goal.trim() || !title} onClick={() => generate(true)}>
              Improve my draft
            </button>
          </div>
          {aiError && <p className="error">{aiError}</p>}
          {variants.length > 0 && (
            <div className="variants">
              {variants.map((v, i) => (
                <article key={i} className="variant">
                  <div className="row between">
                    <span className="pill">{v.angle}</span>
                    <button type="button" className="button-ghost small" onClick={() => useVariant(v)}>
                      Use
                    </button>
                  </div>
                  <strong>{v.title}</strong>
                  <p>{v.body}</p>
                  <p className="muted small">
                    → {v.destination_key}
                    {v.destination_params.length ? ` (${v.destination_params.map((p) => `${p.key}=${p.value || "?"}`).join(", ")})` : ""} · {v.channel}
                  </p>
                  <p className="muted small">{v.why}</p>
                </article>
              ))}
            </div>
          )}
        </div>

        <div className="panel panel-pad stack tight">
          <div className="eyebrow">Message</div>
          <label className="field">
            <span className="label">Campaign name (internal)</span>
            <input className="input" placeholder="ludo_winback_oct" value={name} onChange={(e) => setName(e.target.value)} />
          </label>
          <label className="field">
            <span className="row between">
              <span className="label">Title</span>
              <Counter value={title} max={50} />
            </span>
            <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} />
          </label>
          <label className="field">
            <span className="row between">
              <span className="label">Body</span>
              <Counter value={body} max={140} />
            </span>
            <textarea className="input" rows={3} value={body} onChange={(e) => setBody(e.target.value)} />
          </label>
          <div className="row">
            <label className="field">
              <span className="label">Image URL (optional, https)</span>
              <input className="input" placeholder="https://…/banner.png" value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} />
            </label>
            <label className="field">
              <span className="label">Android channel</span>
              <select className="input" value={channel} onChange={(e) => setChannel(e.target.value as typeof channel)}>
                {CHANNELS.map(([id, label]) => (
                  <option key={id} value={id}>
                    {label}
                  </option>
                ))}
              </select>
            </label>
          </div>
        </div>

        <div className="panel panel-pad stack tight">
          <div className="eyebrow">On tap</div>
          <DeeplinkBuilder value={link} onChange={setLink} />
        </div>

        <div className="panel panel-pad stack tight">
          <div className="eyebrow">Audience & schedule</div>
          <div className="segmented">
            {(Object.keys(AUDIENCE) as AudienceKind[])
              .filter((k) => k !== "token")
              .map((k) => (
                <button key={k} type="button" className={audience === k ? "on" : ""} onClick={() => setAudience(k)}>
                  {AUDIENCE[k].label}
                </button>
              ))}
          </div>
          {audience !== "all" && (
            <input className="input" placeholder={AUDIENCE[audience].placeholder} value={audienceValue} onChange={(e) => setAudienceValue(e.target.value)} />
          )}
          {audience === "all" && <p className="muted small">Topic <code>mira_road_users</code>: every device that has signed in.</p>}
          <div className="segmented">
            <button type="button" className={when === "now" ? "on" : ""} onClick={() => setWhen("now")}>
              Send now
            </button>
            <button type="button" className={when === "later" ? "on" : ""} onClick={() => setWhen("later")}>
              Schedule
            </button>
          </div>
          {when === "later" && (
            <label className="field">
              <span className="label">Send at (your local time)</span>
              <input className="input" type="datetime-local" value={sendAt} onChange={(e) => setSendAt(e.target.value)} />
              <span className="muted small">Dispatched by the scheduled Cloud Function within ~5 minutes of this time.</span>
            </label>
          )}
          <div className="actions">
            <button type="button" className="button" disabled={busy || !title || !body || (when === "later" && !sendAt)} onClick={() => send(false)}>
              {busy ? "Working…" : when === "later" ? "Schedule campaign" : "Send campaign"}
            </button>
          </div>
          <div className="divider" />
          <label className="field">
            <span className="label">Test on a device first</span>
            <div className="row">
              <input className="input" placeholder={AUDIENCE.token.placeholder} value={testToken} onChange={(e) => setTestToken(e.target.value)} />
              <button type="button" className="button-secondary" disabled={busy || !title || !body || !testToken} onClick={() => send(true)}>
                Send test
              </button>
            </div>
          </label>
          {status && <p className={status.kind === "ok" ? "ok" : "error"}>{status.text}</p>}
        </div>
      </section>

      <aside className="stack preview-col">
        <div className="panel panel-pad stack tight">
          <div className="eyebrow">Preview</div>
          <div className="phone android">
            <div className="notif">
              <div className="notif-head">
                <span className="app-dot" /> Hash · now
              </div>
              <strong>{title || "Notification title"}</strong>
              <p>{body || "The body text shows here. Keep the hook in the first line."}</p>
              {imageUrl && /^https:\/\//.test(imageUrl) && (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={imageUrl} alt="" />
              )}
            </div>
          </div>
          <div className="phone ios">
            <div className="notif">
              <div className="notif-head">
                <span className="app-dot" /> HASH <span className="muted">now</span>
              </div>
              <strong>{title || "Notification title"}</strong>
              <p className="clamp">{body || "The body text shows here."}</p>
            </div>
          </div>
          <p className="muted small">
            On tap: {resolved?.built ? <code>{resolved.built.value}</code> : resolved ? "incomplete link" : "opens the app"}
            {resolved && !resolved.dest.opens ? " (lands on Home today)" : ""}
          </p>
        </div>
        <div className="panel panel-pad stack tight">
          <div className="eyebrow">FCM data payload</div>
          <pre className="code">{JSON.stringify({ channel, data }, null, 2)}</pre>
        </div>
      </aside>
    </div>
  );
}
