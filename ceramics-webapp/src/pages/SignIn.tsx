import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function SignIn() {
  const { loading, isSignedIn, signIn } = useAuth();

  if (loading) return <div className="page-loading">Loading…</div>;
  if (isSignedIn) return <Navigate to="/" replace />;

  return (
    <div className="page page-narrow">
      <h1>Sign in</h1>
      <p>Continue with your account to check out faster or manage the store.</p>
      <button type="button" className="button button-primary" onClick={() => signIn()}>
        Sign in with SSO
      </button>
    </div>
  );
}
