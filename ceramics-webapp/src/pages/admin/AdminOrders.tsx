import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import * as api from "../../api";
import type { Order, OrderStatus } from "../../api";
import { formatMoney } from "../../format";

const STATUS_OPTIONS: (OrderStatus | "all")[] = ["all", "pending", "paid", "shipped", "delivered", "cancelled"];

export default function AdminOrders() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [status, setStatus] = useState<OrderStatus | "all">("all");
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    api
      .listOrders({ limit: 100, status: status === "all" ? undefined : status })
      .then(({ data, error }) => {
        if (error) {
          setLoadError("Could not load orders.");
          return;
        }
        setOrders(data?.data ?? []);
      })
      .finally(() => setLoading(false));
  }, [status]);

  return (
    <div className="page">
      <div className="row row-between">
        <h1>Orders</h1>
        <select value={status} onChange={(e) => setStatus(e.target.value as OrderStatus | "all")}>
          {STATUS_OPTIONS.map((s) => (
            <option key={s} value={s}>
              Status: {s === "all" ? "All" : s}
            </option>
          ))}
        </select>
      </div>
      {loading && <p>Loading orders…</p>}
      {loadError && <p className="error-text">{loadError}</p>}
      {!loading && !loadError && (
        <table className="data-table">
          <thead>
            <tr>
              <th>Order</th>
              <th>Customer</th>
              <th>Total</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.id}>
                <td>
                  <Link to={`/admin/orders/${order.id}`}>#{order.id}</Link>
                </td>
                <td>{order.guestEmail ?? (order.customerId ? "Signed-in customer" : "Guest")}</td>
                <td>{formatMoney(order.total)}</td>
                <td>{order.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
