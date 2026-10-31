import { redirect } from "next/navigation";
import { LoginForm } from "@/components/login-form";
import { getAdminSession } from "@/lib/auth";

export default async function LoginPage() {
  const session = await getAdminSession();
  if (session) {
    redirect("/dashboard");
  }

  return (
    <main className="login-shell">
      <section className="panel login-card">
        <p className="eyebrow">Hash Admin</p>
        <h1 className="title">External Cafe Likes</h1>
        <p className="subtitle">
          Sign in with an approved Firebase admin account to review leaderboard
          performance, recent likes, and cafe-level like activity.
        </p>
        <LoginForm />
      </section>
    </main>
  );
}
