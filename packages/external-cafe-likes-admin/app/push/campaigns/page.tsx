import { CancelButton } from "@/components/cancel-campaign-button";
import { PushShell } from "@/components/push-shell";
import { requireAdminSession } from "@/lib/auth";
import { listCampaigns } from "@/lib/push";

function formatDate(value: string | null) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("en-IN", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value));
}

export default async function CampaignsPage() {
  const session = await requireAdminSession();
  const campaigns = await listCampaigns(100);

  return (
    <PushShell
      active="/push/campaigns"
      email={session.email}
      title="Campaigns"
      subtitle="Every push sent or scheduled from this studio. Opens are logged by the app as notification_opened with this campaign_id in Firebase Analytics."
    >
      <div className="panel panel-pad">
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Campaign</th>
                <th>Message</th>
                <th>Audience</th>
                <th>On tap</th>
                <th>Status</th>
                <th>When</th>
              </tr>
            </thead>
            <tbody>
              {campaigns.length === 0 && (
                <tr>
                  <td colSpan={6} className="muted">
                    Nothing sent yet.
                  </td>
                </tr>
              )}
              {campaigns.map((c) => (
                <tr key={c.id}>
                  <td>
                    <strong>{c.name}</strong>
                    <code className="small">{c.id}</code>
                    <span className="muted small">{c.createdBy}</span>
                  </td>
                  <td>
                    <strong>{c.title}</strong>
                    <span className="muted">{c.body}</span>
                  </td>
                  <td>{c.audience}</td>
                  <td>{c.link ? <code>{c.link}</code> : "—"}</td>
                  <td>
                    <span className={`status ${c.status}`}>{c.test ? `test · ${c.status}` : c.status}</span>
                    {c.error && <span className="error small">{c.error}</span>}
                    {c.status === "scheduled" && <CancelButton id={c.id} />}
                  </td>
                  <td>
                    {c.status === "scheduled" ? `Due ${formatDate(c.sendAt)}` : formatDate(c.sentAt ?? c.createdAt)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </PushShell>
  );
}
