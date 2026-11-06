import { FlagSwitch } from "@/components/flag-switch";
import { PushShell } from "@/components/push-shell";
import { requireAdminSession } from "@/lib/auth";
import { FLAGS, PLATFORMS, readFlags, type FlagState } from "@/lib/flags";

export const dynamic = "force-dynamic";

export default async function FlagsPage() {
  const session = await requireAdminSession();
  let states: FlagState[] = [];
  let error: string | null = null;
  try {
    states = await readFlags();
  } catch (e) {
    error = e instanceof Error ? e.message : "Could not reach Firebase Remote Config.";
  }

  return (
    <PushShell
      active="/push/flags"
      email={session.email}
      title="Feature flags"
      subtitle="Switch app features for everyone without a new release. Changes reach users the next time they open the app (usually within minutes)."
    >
      {error && <div className="panel panel-pad warn">{error}</div>}
      <section className="stack">
        {FLAGS.map((flag) => {
          const state = states.find((s) => s.key === flag.key);
          return (
            <div key={flag.key} className="panel panel-pad">
              <div className="row between">
                <div className="stack tight">
                  <strong>{flag.label}</strong>
                  <span className="muted small">{flag.description}</span>
                  <code className="small">{flag.key}</code>
                </div>
                {state && (
                  <div className="stack tight">
                    {PLATFORMS.map((pl) => (
                      <FlagSwitch
                        key={pl.id}
                        flagKey={flag.key}
                        label={flag.label}
                        platform={pl.id}
                        platformLabel={pl.label}
                        enabled={state.platforms[pl.id]}
                        warning={pl.id === "android" ? flag.warning : undefined}
                      />
                    ))}
                  </div>
                )}
              </div>
              {flag.warning && <p className="warn small">{flag.warning}</p>}
              {state?.updatedAt && (
                <p className="muted small">
                  Remote Config last published {new Date(state.updatedAt).toLocaleString("en-IN")}
                  {state.updatedBy ? ` by ${state.updatedBy}` : ""}
                </p>
              )}
            </div>
          );
        })}
      </section>
    </PushShell>
  );
}
