import { useEffect, useState } from "react";
import { Navigate } from "react-router-dom";
import { handleCallback } from "../auth";
import { useAuth } from "../context/AuthContext";

export default function Callback() {
  const { refresh } = useAuth();
  const [state, setState] = useState<"pending" | "done" | "error">("pending");

  useEffect(() => {
    handleCallback()
      .then(async () => {
        await refresh();
        setState("done");
      })
      .catch(() => setState("error"));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (state === "done") return <Navigate to="/" replace />;
  if (state === "error") {
    return (
      <div className="page page-narrow">
        <h1>Sign-in failed</h1>
        <p>Something went wrong completing sign-in. Please try again.</p>
        <a href="/" className="button">
          Back to shop
        </a>
      </div>
    );
  }

  return <div className="page-loading">Completing sign-in…</div>;
}
