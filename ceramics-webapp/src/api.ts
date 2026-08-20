import createClient from "openapi-fetch";
import type { paths, components } from "./generated/ceramics-api";
import { getAccessToken, signIn } from "./auth";

// Same-origin: nginx reverse-proxies /api/ to ceramics-api (CERAMICS_API_URL,
// pod env). Never the public gateway URL, never a window._env_ key.
export const ceramicsApi = createClient<paths>({ baseUrl: "/api" });

export type Product = components["schemas"]["Product"];
export type ProductInput = components["schemas"]["ProductInput"];
export type Cart = components["schemas"]["Cart"];
export type CartItem = components["schemas"]["CartItem"];
export type Order = components["schemas"]["Order"];
export type OrderInput = components["schemas"]["OrderInput"];
export type OrderStatusInput = components["schemas"]["OrderStatusInput"];
export type ApiError = components["schemas"]["Error"];
export type OrderStatus = NonNullable<Order["status"]>;

// ceramics-api's committed openapi.yaml documents the Order schema without a
// hosted-checkout redirect field, but the design (design.md / issue #7)
// requires POST /orders to hand back a Stripe-hosted checkout URL to
// redirect the browser to. The schema has no `additionalProperties: false`,
// so the live response may carry this field even though it isn't typed.
// Widen locally rather than editing the committed spec.
export type OrderWithCheckout = Order & { checkoutUrl?: string | null };

/** Attaches the bearer token when signed in; anonymous (guest) requests omit it. */
async function authHeaders(): Promise<Record<string, string>> {
  const token = await getAccessToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

/** Wraps a call needing auth: on 401, restart sign-in (expired/invalid session). */
async function withAuthFallback<T>(run: () => Promise<T>): Promise<T> {
  const result = await run();
  const maybeResponse = result as unknown as { response?: Response };
  if (maybeResponse?.response?.status === 401) {
    await signIn();
  }
  return result;
}

export async function listProducts(limit = 20, offset = 0) {
  return ceramicsApi.GET("/products", { params: { query: { limit, offset } } });
}

export async function getProduct(productId: string) {
  return ceramicsApi.GET("/products/{productId}", { params: { path: { productId } } });
}

export async function createProduct(body: ProductInput) {
  const headers = await authHeaders();
  return withAuthFallback(() => ceramicsApi.POST("/products", { body, headers }));
}

export async function updateProduct(productId: string, body: ProductInput) {
  const headers = await authHeaders();
  return withAuthFallback(() =>
    ceramicsApi.PATCH("/products/{productId}", { params: { path: { productId } }, body, headers }),
  );
}

export async function deleteProduct(productId: string) {
  const headers = await authHeaders();
  return withAuthFallback(() =>
    ceramicsApi.DELETE("/products/{productId}", { params: { path: { productId } }, headers }),
  );
}

export async function createCart() {
  return ceramicsApi.POST("/carts", {});
}

export async function getCart(cartId: string) {
  return ceramicsApi.GET("/carts/{cartId}", { params: { path: { cartId } } });
}

export async function addCartItem(cartId: string, productId: string, quantity: number) {
  return ceramicsApi.POST("/carts/{cartId}/items", {
    params: { path: { cartId } },
    body: { productId, quantity },
  });
}

export async function updateCartItem(cartId: string, itemId: string, quantity: number) {
  return ceramicsApi.PATCH("/carts/{cartId}/items/{itemId}", {
    params: { path: { cartId, itemId } },
    body: { quantity },
  });
}

export async function removeCartItem(cartId: string, itemId: string) {
  return ceramicsApi.DELETE("/carts/{cartId}/items/{itemId}", {
    params: { path: { cartId, itemId } },
  });
}

export async function listOrders(opts?: { limit?: number; offset?: number; status?: OrderStatus }) {
  const headers = await authHeaders();
  return withAuthFallback(() =>
    ceramicsApi.GET("/orders", {
      params: {
        query: {
          limit: opts?.limit,
          offset: opts?.offset,
          status: opts?.status,
        },
      },
      headers,
    }),
  );
}

export async function createOrder(body: OrderInput) {
  // Guest checkout must work unauthenticated; attach a token only when signed in.
  const headers = await authHeaders();
  return ceramicsApi.POST("/orders", { body, headers });
}

export async function getOrder(orderId: string) {
  const headers = await authHeaders();
  return ceramicsApi.GET("/orders/{orderId}", { params: { path: { orderId } }, headers });
}

export async function updateOrderStatus(orderId: string, status: OrderStatusInput["status"]) {
  const headers = await authHeaders();
  return withAuthFallback(() =>
    ceramicsApi.PATCH("/orders/{orderId}/status", {
      params: { path: { orderId } },
      body: { status },
      headers,
    }),
  );
}
