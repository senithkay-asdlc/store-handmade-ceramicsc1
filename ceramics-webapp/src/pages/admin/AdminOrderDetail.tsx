import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import * as api from "../../api";
import type { Order, OrderStatus } from "../../api";
import { formatMoney } from "../../format";
import { useProductNames } from "../../hooks/useProductNames";

const STATUS_OPTIONS: OrderStatus[] = ["pending", "paid", "shipped", "delivered", "cancelled"];

export default function AdminOrderDetail() {
  const { orderId } = useParams<{ orderId: string }>();
  const navigate = useNavigate();

  const [order, setOrder] = useState<Order | null>(null);
  const [nextStatus, setNextStatus] = useState<OrderStatus>("pending");
  const [notFound, setNotFound] = useState(false);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  const names = useProductNames(order?.items.map((i) => i.productId) ?? []);

  useEffect(() => {
    if (!orderId) return;
    api.getOrder(orderId).then(({ data, error }) => {
      if (error || !data) {
        setNotFound(true);
        return;
      }
      setOrder(data);
      setNextStatus(data.status);
    });
  }, [orderId]);

  async function handleSaveStatus() {
    if (!orderId) return;
    setSaving(true);
    setSaveError(null);
    const { data, error } = await api.updateOrderStatus(orderId, nextStatus);
    setSaving(false);
    if (error || !data) {
      setSaveError((error as { message?: string } | undefined)?.message ?? "Could not update status.");
      return;
    }
    navigate("/admin/orders");
  }

  if (notFound) {
    return (
      <div className="page">
        <p>Order not found.</p>
        <Link to="/admin/orders">Back to Orders</Link>
      </div>
    );
  }

  if (!order) return <div className="page">Loading…</div>;

  return (
    <div className="page">
      <nav className="breadcrumb">
        <Link to="/admin/orders">Orders</Link> / #{order.id}
      </nav>
      <div className="row">
        <h1>Order #{order.id}</h1>
        <span className="badge badge-info">{order.status}</span>
      </div>
      <table className="data-table">
        <thead>
          <tr>
            <th>Item</th>
            <th>Qty</th>
            <th>Price</th>
          </tr>
        </thead>
        <tbody>
          {order.items.map((item, idx) => (
            <tr key={idx}>
              <td>{names[item.productId] ?? item.productId}</td>
              <td>{item.quantity}</td>
              <td>{formatMoney(item.unitPrice * item.quantity)}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <p>
        Shipping: {formatMoney(order.shippingFee)} — Total: {formatMoney(order.total)}
      </p>
      {saveError && <p className="error-text">{saveError}</p>}
      <div className="row">
        <select value={nextStatus} onChange={(e) => setNextStatus(e.target.value as OrderStatus)}>
          {STATUS_OPTIONS.map((s) => (
            <option key={s} value={s}>
              Update status: {s}
            </option>
          ))}
        </select>
        <button type="button" className="button button-primary" onClick={handleSaveStatus} disabled={saving}>
          {saving ? "Saving…" : "Save status"}
        </button>
      </div>
    </div>
  );
}
