"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

export function CancelButton({ id }: { id: string }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  return (
    <button
      type="button"
      className="button-ghost small"
      disabled={busy}
      onClick={async () => {
        if (!window.confirm("Cancel this scheduled push?")) return;
        setBusy(true);
        const res = await fetch(`/api/push/campaigns/${id}`, { method: "DELETE" });
        if (!res.ok) window.alert((await res.json()).error);
        setBusy(false);
        router.refresh();
      }}
    >
      Cancel
    </button>
  );
}
