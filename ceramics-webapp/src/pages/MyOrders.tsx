import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import * as api from "../api";
import type { Order } from "../api";
import { formatDate, formatMoney } from "../format";

export default function MyOrders() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    api
      .listOrders({ limit: 100 })
      .then(({ data, error }) => {
        if (cancelled) return;
        if (error) {
          setLoadError("Could not load your orders.");
          return;
        }
        setOrders(data?.data ?? []);
      })
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="page">
      <h1>My Orders</h1>
      {loading && <p>Loading orders…</p>}
      {loadError && <p className="error-text">{loadError}</p>}
      {!loading && !loadError && orders.length === 0 && <p>You haven't placed any orders yet.</p>}
      {orders.length > 0 && (
        <table className="data-table">
          <thead>
            <tr>
              <th>Order</th>
              <th>Placed</th>
              <th>Total</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.id}>
                <td>
                  <Link to={`/my-orders/${order.id}`}>#{order.id}</Link>
                </td>
                <td>{formatDate(order.createdAt)}</td>
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
