# Security design

## Roles → permissions

## Authentication (Thunder)

- Shared `thunder-app` dependency name: **`user-auth`**, declared identically
on `ceramics-webapp` and `ceramics-api` — this shared name ties browser
sign-in to the tokens `ceramics-api` validates.
- Scopes: default `openid profile email`.
- Components on the sign-in side: `ceramics-webapp` (OIDC + PKCE in the SPA).
- Components on the token-validation side: `ceramics-api` (validates the
bearer token on every protected endpoint).
- Catalog browsing (`GET /products`, `GET /products/{id}`) is public and
unauthenticated — it serves stories 1–2 for anonymous shoppers before any
sign-in decision. Guest checkout (`POST /orders` without a token) is also
unauthenticated by product decision (PRD: guest checkout allowed).

## Role resolution

- `ceramics-api` resolves the caller's role from the validated Thunder token:
a token with the `store-admin` role claim (or group membership, as
provisioned in Thunder) is treated as Store Admin; any other valid token is
a signed-in Shopper; no token (or a guest checkout request) is treated as a
guest Shopper.
- Admin-only endpoints (product management, inventory updates, order-status
updates, listing all orders) deny by default: a caller without the
`store-admin` role receives `403`.
- A signed-in Shopper may only read their own orders (`GET /orders` is scoped
server-side to the caller's resolved customer id); requesting another
customer's order returns `403`.