import type { ReactNode } from "react";
import { useAuth } from "../context/AuthContext";

/** Blocks a signed-in-only route: no navigation withheld from the render tree,
 * but the guarded content never mounts for an anonymous visitor. */
export default function RequireAuth({ children }: { children: ReactNode }) {
  const { loading, isSignedIn, signIn } = useAuth();

  if (loading) return <div className="page-loading">Loading…</div>;

  if (!isSignedIn) {
    return (
      <div className="page-narrow">
        <h1>Sign in required</h1>
        <p>Sign in to view this page.</p>
        <button type="button" className="button button-primary" onClick={() => signIn()}>
          Sign in with SSO
        </button>
      </div>
    );
  }

  return <>{children}</>;
}
