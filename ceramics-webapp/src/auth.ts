import { UserManager, WebStorageStateStore, type User } from "oidc-client-ts";
import { env } from "./env";

// Thunder OIDC + PKCE. The OAuth client itself is platform-owned — client_id,
// the registered redirect URI, etc. arrive via window._env_ (env.ts); nothing
// here is computed or hardcoded.
export const userManager = new UserManager({
  authority: env.USER_AUTH_ISSUER,
  client_id: env.USER_AUTH_CLIENT_ID,
  redirect_uri: window.location.origin + "/callback",
  post_logout_redirect_uri: window.location.origin,
  response_type: "code",
  scope: env.USER_AUTH_SCOPES,
  userStore: new WebStorageStateStore({ store: window.localStorage }),
  automaticSilentRenew: true,
  loadUserInfo: false,
});

export async function signIn(): Promise<void> {
  await userManager.signinRedirect();
}

export async function handleCallback(): Promise<User> {
  return userManager.signinRedirectCallback();
}

// No end_session_endpoint in Thunder's discovery document → signoutRedirect()
// rejects. Drop the LOCAL session instead and reload.
export async function signOut(): Promise<void> {
  try {
    await userManager.signoutRedirect();
  } catch {
    await userManager.removeUser();
    window.location.assign("/");
  }
}

// null ONLY when there is no session to renew — an expired one renews silently.
export async function currentUser(): Promise<User | null> {
  const user = await userManager.getUser();
  if (user && !user.expired) return user;
  try {
    return await userManager.signinSilent();
  } catch {
    return null;
  }
}

export async function getAccessToken(): Promise<string | null> {
  const user = await currentUser();
  return user?.access_token ?? null;
}

export async function getRoles(): Promise<string[]> {
  const user = await currentUser();
  const groups = user?.profile?.groups;
  return Array.isArray(groups) ? (groups as string[]) : [];
}

// security.md: a token carrying the store-admin role claim/group is Store
// Admin. Match case-insensitively on the keyword so a renamed group in
// Thunder's admin console still resolves correctly.
export function isStoreAdminRole(groups: string[]): boolean {
  return groups.some((g) => /admin/i.test(g));
}

export function displayName(user: User | null): string {
  if (!user) return "";
  const profile = user.profile as { email?: string; name?: string; sub?: string };
  return profile.name ?? profile.email ?? profile.sub ?? "Account";
}
