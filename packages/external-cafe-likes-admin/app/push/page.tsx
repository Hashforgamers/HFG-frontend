import { PushComposer } from "@/components/push-composer";
import { PushShell } from "@/components/push-shell";
import { TrendingAutopilot } from "@/components/trending-autopilot";
import { requireAdminSession } from "@/lib/auth";
import { listCampaigns } from "@/lib/push";
import { getTrendingState } from "@/lib/trending";

export default async function PushPage() {
  const session = await requireAdminSession();
  const [campaigns, trending] = await Promise.all([listCampaigns(200), getTrendingState()]);
  const live = campaigns.filter((c) => !c.test);
  const dayAgo = Date.now() - 24 * 60 * 60 * 1000;

  return (
    <PushShell
      active="/push"
      email={session.email}
      title="Compose a push"
      subtitle="Let AI draft the copy, pick where the tap lands, preview it on Android and iOS, test on your phone, then send or schedule."
    >
      <section className="grid stats-grid">
        <div className="panel stat-card">
          <div className="stat-value">{live.filter((c) => c.status === "sent" && Date.parse(c.sentAt ?? "") > dayAgo).length}</div>
          <div className="stat-label">Campaigns sent, last 24h</div>
        </div>
        <div className="panel stat-card">
          <div className="stat-value">{live.filter((c) => c.status === "scheduled").length}</div>
          <div className="stat-label">Scheduled</div>
        </div>
        <div className="panel stat-card">
          <div className="stat-value">{live.filter((c) => c.status === "failed").length}</div>
          <div className="stat-label">Failed (last 200)</div>
        </div>
      </section>
      <TrendingAutopilot initial={trending} />
      <PushComposer />
    </PushShell>
  );
}
