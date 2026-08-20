import type { ReactNode } from "react";
import { useAuth } from "../context/AuthContext";

/** Blocks the admin area for anyone without the Store Admin role — signed out
 * (prompt sign-in) or signed in without the role (403, not a redirect loop). */
export default function RequireAdmin({ children }: { children: ReactNode }) {
  const { loading, isSignedIn, isStoreAdmin, signIn } = useAuth();

  if (loading) return <div className="page-loading">Loading…</div>;

  if (!isSignedIn) {
    return (
      <div className="page-narrow">
        <h1>Sign in required</h1>
        <p>Sign in with a Store Admin account to manage the store.</p>
        <button type="button" className="button button-primary" onClick={() => signIn()}>
          Sign in with SSO
        </button>
      </div>
    );
  }

  if (!isStoreAdmin) {
    return (
      <div className="page-narrow">
        <h1>403 — Forbidden</h1>
        <p>Your account does not have Store Admin access.</p>
      </div>
    );
  }

  return <>{children}</>;
}
