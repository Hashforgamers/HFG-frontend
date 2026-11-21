import Link from "next/link";
import { notFound } from "next/navigation";
import { requireAdminSession } from "@/lib/auth";
import { getCafeDetail } from "@/lib/firestore";
import { SignOutButton } from "@/components/sign-out-button";

function formatDate(value: string | null) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("en-IN", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

type CafeDetailPageProps = {
  params: Promise<{
    cafeId: string;
  }>;
};

export default async function CafeDetailPage({ params }: CafeDetailPageProps) {
  await requireAdminSession();
  const { cafeId } = await params;
  const detail = await getCafeDetail(decodeURIComponent(cafeId));

  if (!detail) {
    notFound();
  }

  const { cafe, likes, likesCount } = detail;

  return (
    <main className="shell">
      <div className="container stack">
        <header className="page-header">
          <div>
            <p className="eyebrow">Cafe Drilldown</p>
            <h1 className="title">{cafe.name}</h1>
            <p className="subtitle">
              Review the external cafe document, confirm like totals, and inspect
              the most recent like documents written to Firestore.
            </p>
          </div>

          <div className="actions">
            <Link className="button-ghost" href="/dashboard">
              Back To Dashboard
            </Link>
            <Link
              className="button-secondary"
              href={`/api/export/cafes/${encodeURIComponent(cafe.id)}/likes`}
            >
              Export Likes CSV
            </Link>
            <SignOutButton />
          </div>
        </header>

        <section className="panel panel-pad">
          <div className="kvs">
            <div className="kv">
              <div className="kv-label">Document ID</div>
              <div className="kv-value">
                <code>{cafe.id}</code>
              </div>
            </div>
            <div className="kv">
              <div className="kv-label">Place ID</div>
              <div className="kv-value">
                <code>{cafe.placeId || "—"}</code>
              </div>
            </div>
            <div className="kv">
              <div className="kv-label">Vicinity</div>
              <div className="kv-value">{cafe.vicinity || "—"}</div>
            </div>
            <div className="kv">
              <div className="kv-label">Rating</div>
              <div className="kv-value">{cafe.rating ?? "—"}</div>
            </div>
            <div className="kv">
              <div className="kv-label">Total Likes</div>
              <div className="kv-value">{cafe.totalLikes}</div>
            </div>
            <div className="kv">
              <div className="kv-label">Likes Subdocs Count</div>
              <div className="kv-value">{likesCount}</div>
            </div>
            <div className="kv">
              <div className="kv-label">Created At</div>
              <div className="kv-value">{formatDate(cafe.createdAt)}</div>
            </div>
            <div className="kv">
              <div className="kv-label">Updated At</div>
              <div className="kv-value">{formatDate(cafe.updatedAt)}</div>
            </div>
            <div className="kv">
              <div className="kv-label">Last Liked At</div>
              <div className="kv-value">{formatDate(cafe.lastLikedAt)}</div>
            </div>
          </div>
        </section>

        <section className="panel panel-pad">
          <div className="toolbar">
            <div>
              <div className="eyebrow">Recent Likes</div>
              <div className="muted">
                Ordered by <code>created_at desc</code>
              </div>
            </div>
          </div>

          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>User Key</th>
                  <th>User ID</th>
                  <th>Firebase UID</th>
                  <th>Device ID</th>
                  <th>Created At</th>
                </tr>
              </thead>
              <tbody>
                {likes.map((like) => (
                  <tr key={like.id}>
                    <td>
                      <code>{like.id}</code>
                    </td>
                    <td>{like.userId || "—"}</td>
                    <td>
                      <code>{like.firebaseUid || "—"}</code>
                    </td>
                    <td>
                      <code>{like.deviceId || "—"}</code>
                    </td>
                    <td>{formatDate(like.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </main>
  );
}
