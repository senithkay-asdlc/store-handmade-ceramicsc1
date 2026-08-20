import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import type { User } from "oidc-client-ts";
import { currentUser, getRoles, isStoreAdminRole, signIn, signOut } from "../auth";

type AuthState = {
  loading: boolean;
  user: User | null;
  roles: string[];
  isSignedIn: boolean;
  isStoreAdmin: boolean;
  signIn: () => Promise<void>;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
};

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<User | null>(null);
  const [roles, setRoles] = useState<string[]>([]);

  async function refresh() {
    const u = await currentUser();
    setUser(u);
    setRoles(u ? await getRoles() : []);
  }

  useEffect(() => {
    refresh().finally(() => setLoading(false));
  }, []);

  const value: AuthState = {
    loading,
    user,
    roles,
    isSignedIn: user != null,
    isStoreAdmin: isStoreAdminRole(roles),
    signIn,
    signOut,
    refresh,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
