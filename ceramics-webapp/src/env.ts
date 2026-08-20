// Typed read of the platform-mounted runtime config. The platform mounts
// /env-config.js into the served root at request time — this is NEVER
// generated or committed here, and NEVER a build-time (import.meta.env / .env)
// mechanism.
type Env = {
  // user-auth (platform-resource, thunder-app) — OIDC config for the SPA.
  USER_AUTH_CLIENT_ID: string;
  USER_AUTH_ISSUER: string;
  USER_AUTH_JWKS_URL: string;
  USER_AUTH_SCOPES: string;
};

declare global {
  interface Window {
    _env_: Env;
  }
}

if (!window._env_) {
  throw new Error(
    "window._env_ not set — /env-config.js failed to load. " +
      "The platform mounts this file; if you see this locally, host " +
      "/env-config.js from your dev server.",
  );
}

export const env: Env = window._env_;
