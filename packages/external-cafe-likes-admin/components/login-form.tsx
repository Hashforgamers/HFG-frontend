"use client";

import { useState } from "react";
import type { FormEvent } from "react";
import { useRouter } from "next/navigation";
import {
  GoogleAuthProvider,
  signInWithEmailAndPassword,
  signInWithPopup,
  type UserCredential,
} from "firebase/auth";
import { firebaseAuth } from "@/lib/firebase-client";

export function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const signIn = async (getCredential: () => Promise<UserCredential>) => {
    setLoading(true);
    setError(null);

    try {
      const credential = await getCredential();
      const idToken = await credential.user.getIdToken();

      const response = await fetch("/api/session", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ idToken }),
      });

      if (!response.ok) {
        const payload = (await response.json().catch(() => null)) as
          | { error?: string }
          | null;
        throw new Error(payload?.error || "Unable to create admin session.");
      }

      router.push("/dashboard");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign-in failed.");
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    void signIn(() => signInWithEmailAndPassword(firebaseAuth, email, password));
  };

  return (
    <form className="login-form" onSubmit={handleSubmit}>
      <div>
        <div className="label">Admin Email</div>
        <input
          className="input"
          type="email"
          autoComplete="email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          placeholder="admin@hashforgamers.com"
          required
        />
      </div>

      <div>
        <div className="label">Password</div>
        <input
          className="input"
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          placeholder="Enter your password"
          required
        />
      </div>

      {error ? <div className="error">{error}</div> : null}

      <button className="button" type="submit" disabled={loading}>
        {loading ? "Signing in..." : "Sign In To Admin"}
      </button>

      <button
        className="button-secondary"
        type="button"
        disabled={loading}
        onClick={() => void signIn(() => signInWithPopup(firebaseAuth, new GoogleAuthProvider()))}
      >
        Sign in with Google
      </button>
    </form>
  );
}
