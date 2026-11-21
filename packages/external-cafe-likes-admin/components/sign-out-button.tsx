"use client";

import { useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { firebaseAuth } from "@/lib/firebase-client";

export function SignOutButton() {
  const router = useRouter();

  const handleClick = async () => {
    await fetch("/api/session", { method: "DELETE" });
    await signOut(firebaseAuth).catch(() => null);
    router.push("/login");
    router.refresh();
  };

  return (
    <button className="button-ghost" type="button" onClick={handleClick}>
      Sign Out
    </button>
  );
}
