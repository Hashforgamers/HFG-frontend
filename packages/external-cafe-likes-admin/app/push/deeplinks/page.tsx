import { DeeplinkStudio } from "@/components/deeplink-studio";
import { PushShell } from "@/components/push-shell";
import { requireAdminSession } from "@/lib/auth";
import { DESTINATIONS } from "@/lib/deeplinks";

export default async function DeeplinksPage() {
  const session = await requireAdminSession();
  return (
    <PushShell
      active="/push/deeplinks"
      email={session.email}
      title="Deep links"
      subtitle="Build tracked links for pushes, WhatsApp, Instagram and QR codes. hash:// links open the app directly; https links also work from browsers and chats."
    >
      <section className="grid two-col">
        <div className="panel panel-pad">
          <DeeplinkStudio />
        </div>
        <div className="panel panel-pad">
          <div className="eyebrow">Every destination the app knows</div>
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Destination</th>
                  <th>Link</th>
                  <th>Opens</th>
                </tr>
              </thead>
              <tbody>
                {DESTINATIONS.map((d) => (
                  <tr key={d.key}>
                    <td>
                      <strong>{d.label}</strong>
                      <span className="muted small">{d.hint}</span>
                    </td>
                    <td>
                      <code>{d.path.startsWith("route:") ? d.path.slice(6) : `hash://${d.path}`}</code>
                    </td>
                    <td>{d.opens ? <span className="ok">Screen</span> : <span className="warn">Home</span>}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </PushShell>
  );
}
