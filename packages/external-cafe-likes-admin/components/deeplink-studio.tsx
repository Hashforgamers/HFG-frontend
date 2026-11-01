"use client";

import { useState } from "react";
import { DeeplinkBuilder, emptyLink, type LinkState } from "@/components/deeplink-builder";

export function DeeplinkStudio() {
  const [link, setLink] = useState<LinkState>({ ...emptyLink, utm: { source: "whatsapp", medium: "social" } });
  return (
    <div className="stack tight">
      <div className="eyebrow">Link builder</div>
      <DeeplinkBuilder value={link} onChange={setLink} />
    </div>
  );
}
