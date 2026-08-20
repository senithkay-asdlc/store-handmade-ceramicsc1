import { useEffect, useState } from "react";
import * as api from "../api";

/** Resolves productId -> display name for a list of order/cart line items.
 * Order/cart line items only carry productId — fetch each product once and
 * cache it for the lifetime of the hook instance. */
export function useProductNames(productIds: string[]): Record<string, string> {
  const [names, setNames] = useState<Record<string, string>>({});
  const key = productIds.join(",");

  useEffect(() => {
    let cancelled = false;
    const missing = productIds.filter((id) => id && !(id in names));
    if (missing.length === 0) return;
    Promise.all(
      missing.map(async (id) => {
        const { data } = await api.getProduct(id);
        return [id, data?.name ?? id] as const;
      }),
    ).then((pairs) => {
      if (cancelled) return;
      setNames((prev) => {
        const next = { ...prev };
        for (const [id, name] of pairs) next[id] = name;
        return next;
      });
    });
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  return names;
}
