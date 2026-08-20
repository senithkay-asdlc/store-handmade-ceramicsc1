import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import * as api from "../api";
import type { Order } from "../api";
import { formatMoney } from "../format";
import { useProductNames } from "../hooks/useProductNames";

export default function OrderStatusDetail() {
  const { orderId } = useParams<{ orderId: string }>();
  const [order, setOrder] = useState<Order | null>(null);
  const [forbidden, setForbidden] = useState(false);
  const [notFound, setNotFound] = useState(false);

  useEffect(() => {
    if (!orderId) return;
    api.getOrder(orderId).then(({ data, error, response }) => {
      if (response.status === 403) {
        setForbidden(true);
        return;
      }
      if (error || !data) {
        setNotFound(true);
        return;
      }
      setOrder(data);
    });
  }, [orderId]);

  if (forbidden) {
    return (
      <div className="page">
        <p>You cannot view this order.</p>
        <Link to="/my-orders">Back to My Orders</Link>
      </div>
    );
  }

  if (notFound) {
    return (
      <div className="page">
        <p>Order not found.</p>
        <Link to="/my-orders">Back to My Orders</Link>
      </div>
    );
  }

  if (!order) return <OrderStatusDetailLoading />;

  return <OrderStatusDetailView order={order} />;
}

function OrderStatusDetailLoading() {
  return <div className="page">Loading…</div>;
}

function OrderStatusDetailView({ order }: { order: Order }) {
  const names = useProductNames(order.items.map((i) => i.productId));

  return (
    <div className="page">
      <nav className="breadcrumb">
        <Link to="/my-orders">My Orders</Link> / #{order.id}
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
    </div>
  );
}
