import { useEffect, useState } from "react";
import { Link, useParams, useSearchParams } from "react-router-dom";
import * as api from "../api";
import type { Order } from "../api";
import { clearCartId, useCart } from "../context/CartContext";
import { formatMoney } from "../format";

const STATUS_VARIANT: Record<string, string> = {
  paid: "badge-success",
  shipped: "badge-info",
  delivered: "badge-success",
  pending: "badge-warning",
  cancelled: "badge-muted",
};

export default function OrderConfirmation() {
  const { orderId: pathOrderId } = useParams<{ orderId: string }>();
  const [searchParams] = useSearchParams();
  const orderId = pathOrderId ?? searchParams.get("orderId") ?? searchParams.get("order_id") ?? undefined;
  const { refresh } = useCart();

  const [order, setOrder] = useState<Order | null>(null);
  const [notFound, setNotFound] = useState(false);

  useEffect(() => {
    // The order is placed — start a fresh cart for any further shopping.
    clearCartId();
    refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!orderId) return;
    api.getOrder(orderId).then(({ data, error }) => {
      if (error || !data) {
        setNotFound(true);
        return;
      }
      setOrder(data);
    });
  }, [orderId]);

  if (!orderId) {
    return (
      <div className="page">
        <h1>Order Confirmed</h1>
        <p>Thank you — your order was placed. Check your email for confirmation.</p>
        <Link to="/" className="button">
          Back to shop
        </Link>
      </div>
    );
  }

  if (notFound) {
    return (
      <div className="page">
        <p>We could not find that order.</p>
        <Link to="/">Back to shop</Link>
      </div>
    );
  }

  return (
    <div className="page">
      <h1>Order Confirmed</h1>
      {order ? (
        <>
          <span className={`badge ${STATUS_VARIANT[order.status] ?? "badge-info"}`}>
            {order.status}
          </span>
          <p>
            Order #{order.id}
            {order.guestEmail ? ` — confirmation sent to ${order.guestEmail}` : ""}
          </p>
          <p>Shipping: {formatMoney(order.shippingFee)} — Total: {formatMoney(order.total)}</p>
          <p>Estimated delivery: 5-7 business days</p>
        </>
      ) : (
        <p>Loading your order…</p>
      )}
      <Link to="/" className="button">
        Back to shop
      </Link>
    </div>
  );
}
