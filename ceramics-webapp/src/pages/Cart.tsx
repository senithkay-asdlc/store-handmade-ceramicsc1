import { Link, useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext";
import { formatMoney } from "../format";

export default function Cart() {
  const { cart, products, loading, error, updateItem, removeItem } = useCart();
  const navigate = useNavigate();

  const items = cart?.items ?? [];
  const subtotal = items.reduce((sum, item) => {
    const product = products[item.productId];
    return sum + (product?.price ?? 0) * item.quantity;
  }, 0);

  return (
    <div className="page">
      <h1>Your Cart</h1>
      {loading && <p>Loading cart…</p>}
      {error && <p className="error-text">{error}</p>}
      {!loading && items.length === 0 && (
        <p>
          Your cart is empty. <Link to="/">Continue shopping</Link>.
        </p>
      )}
      {items.length > 0 && (
        <>
          <table className="data-table">
            <thead>
              <tr>
                <th>Product</th>
                <th>Quantity</th>
                <th>Price</th>
                <th>Subtotal</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => {
                const product = products[item.productId];
                const maxQty = product ? Math.max(product.stockQuantity, item.quantity) : item.quantity;
                return (
                  <tr key={item.id}>
                    <td>{product?.name ?? item.productId}</td>
                    <td>
                      <select
                        value={item.quantity}
                        onChange={(e) => updateItem(item.id, Number(e.target.value))}
                      >
                        {Array.from({ length: Math.min(maxQty, 10) }, (_, i) => i + 1).map((n) => (
                          <option key={n} value={n}>
                            {n}
                          </option>
                        ))}
                      </select>
                    </td>
                    <td>{formatMoney(product?.price)}</td>
                    <td>{formatMoney((product?.price ?? 0) * item.quantity)}</td>
                    <td>
                      <button type="button" className="link-button" onClick={() => removeItem(item.id)}>
                        Remove
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          <div className="row row-right">
            <span className="total-text">Subtotal: {formatMoney(subtotal)}</span>
          </div>
          <div className="row row-right">
            <button type="button" className="button" onClick={() => navigate("/")}>
              Continue shopping
            </button>
            <button type="button" className="button button-primary" onClick={() => navigate("/checkout")}>
              Checkout
            </button>
          </div>
        </>
      )}
    </div>
  );
}
