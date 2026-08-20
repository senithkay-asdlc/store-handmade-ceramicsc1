export function formatMoney(amount: number | undefined | null): string {
  return `$${(amount ?? 0).toFixed(2)}`;
}

export function formatDate(iso: string | undefined | null): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}
