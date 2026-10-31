import Link from "next/link";
import { requireAdminSession } from "@/lib/auth";
import { getLeaderboard, getRecentLikes } from "@/lib/firestore";
import { SignOutButton } from "@/components/sign-out-button";

function formatDate(value: string | null) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("en-IN", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

type DashboardPageProps = {
  searchParams?: Promise<{
    q?: string;
  }>;
};

export default async function DashboardPage({
  searchParams,
}: DashboardPageProps) {
  const session = await requireAdminSession();
  const resolvedSearchParams = (await searchParams) ?? {};
  const query = resolvedSearchParams.q?.trim() ?? "";

  const [cafes, recentLikes] = await Promise.all([
    getLeaderboard(query, 100),
    getRecentLikes(25),
  ]);

  const totalLikes = cafes.reduce((sum, cafe) => sum + cafe.totalLikes, 0);

  return (
    <main className="shell">
      <div className="container stack">
        <header className="page-header">
          <div>
            <p className="eyebrow">Protected Analytics</p>
            <h1 className="title">External Cafe Likes Dashboard</h1>
            <p className="subtitle">
              Track which external cafes are receiving the most engagement, drill
              into recent liker activity, and export the leaderboard as CSV.
            </p>
          </div>

          <div className="actions">
            <span className="pill">{session.email}</span>
            <Link
              className="button-secondary"
              href={`/api/export/cafes${query ? `?q=${encodeURIComponent(query)}` : ""}`}
            >
              Export CSV
            </Link>
            <SignOutButton />
          </div>
        </header>

        <section className="grid stats-grid">
          <div className="panel stat-card">
            <div className="stat-value">{cafes.length}</div>
            <div className="stat-label">Cafes loaded</div>
          </div>
          <div className="panel stat-card">
            <div className="stat-value">{totalLikes}</div>
            <div className="stat-label">Leaderboard likes in view</div>
          </div>
          <div className="panel stat-card">
            <div className="stat-value">{recentLikes.length}</div>
            <div className="stat-label">Recent likes pulled</div>
          </div>
        </section>

        <section className="grid two-col">
          <div className="panel panel-pad">
            <div className="toolbar">
              <div>
                <div className="eyebrow">Leaderboard</div>
                <div className="muted">
                  Ordered by <code>total_likes desc</code>
                </div>
              </div>

              <form className="search-form" action="/dashboard">
                <input
                  className="input"
                  type="search"
                  name="q"
                  defaultValue={query}
                  placeholder="Search by cafe name or place_id"
                />
                <button className="button" type="submit">
                  Search
                </button>
              </form>
            </div>

            <div className="table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Cafe</th>
                    <th>Place ID</th>
                    <th>Total Likes</th>
                    <th>Rating</th>
                    <th>Last Liked</th>
                  </tr>
                </thead>
                <tbody>
                  {cafes.map((cafe, index) => (
                    <tr key={cafe.id}>
                      <td>{index + 1}</td>
                      <td>
                        <strong>
                          <Link href={`/cafes/${encodeURIComponent(cafe.id)}`}>
                            {cafe.name}
                          </Link>
                        </strong>
                        <span className="muted">{cafe.vicinity || "No vicinity"}</span>
                      </td>
                      <td>
                        <code>{cafe.placeId || "—"}</code>
                      </td>
                      <td>{cafe.totalLikes}</td>
                      <td>{cafe.rating ?? "—"}</td>
                      <td>{formatDate(cafe.lastLikedAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <aside className="stack">
            <section className="panel panel-pad">
              <div className="eyebrow">Recent Likes</div>
              <div className="muted">
                Latest like documents from the <code>likes</code> subcollections.
              </div>
              <div className="stack" style={{ marginTop: 18 }}>
                {recentLikes.map((like) => (
                  <div key={`${like.cafeId}-${like.id}`} className="kv">
                    <div className="kv-label">{formatDate(like.createdAt)}</div>
                    <div className="kv-value">
                      <strong>{like.cafeName}</strong>
                      <div className="muted">
                        {like.userId || like.firebaseUid || like.deviceId || like.id}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          </aside>
        </section>
      </div>
    </main>
  );
}
