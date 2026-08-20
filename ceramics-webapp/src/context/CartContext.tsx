import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import * as api from "../api";
import type { Cart, Product } from "../api";

const CART_ID_KEY = "ceramics.cartId";

type CartState = {
  loading: boolean;
  cart: Cart | null;
  itemCount: number;
  products: Record<string, Product>;
  error: string | null;
  addItem: (productId: string, quantity: number) => Promise<boolean>;
  updateItem: (itemId: string, quantity: number) => Promise<void>;
  removeItem: (itemId: string) => Promise<void>;
  refresh: () => Promise<void>;
  clearError: () => void;
};

const CartContext = createContext<CartState | null>(null);

export function CartProvider({ children }: { children: ReactNode }) {
  const [cartId, setCartId] = useState<string | null>(() => localStorage.getItem(CART_ID_KEY));
  const [cart, setCart] = useState<Cart | null>(null);
  const [products, setProducts] = useState<Record<string, Product>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  async function ensureCart(): Promise<string> {
    if (cartId) return cartId;
    const { data } = await api.createCart();
    const id = data?.id;
    if (!id) throw new Error("Failed to create cart");
    localStorage.setItem(CART_ID_KEY, id);
    setCartId(id);
    return id;
  }

  async function hydrateProducts(items: { productId: string }[]) {
    const missing = items.map((i) => i.productId).filter((id) => !products[id]);
    if (missing.length === 0) return;
    const fetched = await Promise.all(
      missing.map(async (id) => {
        const { data } = await api.getProduct(id);
        return data ?? null;
      }),
    );
    setProducts((prev) => {
      const next = { ...prev };
      for (const p of fetched) if (p) next[p.id] = p;
      return next;
    });
  }

  async function refresh() {
    setLoading(true);
    try {
      const id = cartId ?? (await ensureCart());
      const { data, response } = await api.getCart(id);
      if (response.status === 404) {
        // Cart expired server-side — start a fresh one.
        localStorage.removeItem(CART_ID_KEY);
        setCartId(null);
        setCart(null);
        return;
      }
      if (data) {
        setCart(data);
        await hydrateProducts(data.items);
      }
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function addItem(productId: string, quantity: number): Promise<boolean> {
    setError(null);
    const id = await ensureCart();
    const { data, error: apiError } = await api.addCartItem(id, productId, quantity);
    if (apiError) {
      setError(apiError.message ?? "This item is out of stock.");
      return false;
    }
    if (data) {
      setCart(data);
      await hydrateProducts(data.items);
    }
    return true;
  }

  async function updateItem(itemId: string, quantity: number): Promise<void> {
    if (!cartId) return;
    setError(null);
    const { data, error: apiError } = await api.updateCartItem(cartId, itemId, quantity);
    if (apiError) {
      setError(apiError.message ?? "Could not update quantity.");
      return;
    }
    if (data) setCart(data);
  }

  async function removeItem(itemId: string): Promise<void> {
    if (!cartId) return;
    await api.removeCartItem(cartId, itemId);
    await refresh();
  }

  const itemCount = cart?.items.reduce((sum, i) => sum + i.quantity, 0) ?? 0;

  const value: CartState = {
    loading,
    cart,
    itemCount,
    products,
    error,
    addItem,
    updateItem,
    removeItem,
    refresh,
    clearError: () => setError(null),
  };

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart(): CartState {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart must be used within CartProvider");
  return ctx;
}

export function cartIdSnapshot(): string | null {
  return localStorage.getItem(CART_ID_KEY);
}

export function clearCartId(): void {
  localStorage.removeItem(CART_ID_KEY);
}
