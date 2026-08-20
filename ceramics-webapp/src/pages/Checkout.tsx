import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import * as api from "../api";
import type { OrderWithCheckout } from "../api";
import { FLAT_SHIPPING_FEE } from "../config";
import { formatMoney } from "../format";

export default function Checkout() {
  const { isSignedIn, user } = useAuth();
  const { cart, products } = useCart();
  const navigate = useNavigate();

  const [guestEmail, setGuestEmail] = useState("");
  const [shippingAddress, setShippingAddress] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const items = cart?.items ?? [];
  const subtotal = items.reduce((sum, item) => {
    const product = products[item.productId];
    return sum + (product?.price ?? 0) * item.quantity;
  }, 0);
  const total = subtotal + FLAT_SHIPPING_FEE;

  const signedInEmail = (user?.profile as { email?: string } | undefined)?.email;

  async function handlePay() {
    if (!cart) return;
    if (!isSignedIn && !guestEmail.trim()) {
      setSubmitError("Enter an email address for your order confirmation.");
      return;
    }
    setSubmitError(null);
    setSubmitting(true);
    try {
      const { data, error } = await api.createOrder({
        cartId: cart.id,
        guestEmail: isSignedIn ? undefined : guestEmail.trim(),
        shippingAddress: shippingAddress.trim() || undefined,
      });
      if (error || !data) {
        setSubmitError(
          (error as { message?: string } | undefined)?.message ??
            "Could not place your order — an item may be out of stock.",
        );
        setSubmitting(false);
        return;
      }
      const order = data as OrderWithCheckout;
      if (order.checkoutUrl) {
        window.location.assign(order.checkoutUrl);
        return;
      }
      // No hosted-checkout URL came back — land directly on confirmation
      // rather than stranding the shopper on this page.
      navigate(`/order-confirmation/${order.id}`);
    } catch {
      setSubmitError("Could not reach the store. Please try again.");
      setSubmitting(false);
    }
  }

  if (items.length === 0) {
    return (
      <div className="page">
        <h1>Checkout</h1>
        <p>Your cart is empty — add a product before checking out.</p>
      </div>
    );
  }

  return (
    <div className="page">
      <h1>Checkout</h1>

      {!isSignedIn && (
        <div className="row">
          <Link to="/signin" className="card card-action">
            Sign in for faster checkout
          </Link>
          <div className="card card-selected">Continue as guest</div>
        </div>
      )}

      {isSignedIn ? (
        <p>Signed in as {signedInEmail ?? "your account"} — order confirmation will be sent there.</p>
      ) : (
        <label className="field">
          <span className="field-label">Email (for order confirmation)</span>
          <input
            type="email"
            value={guestEmail}
            onChange={(e) => setGuestEmail(e.target.value)}
            placeholder="jane@example.com"
            required
          />
        </label>
      )}

      <label className="field">
        <span className="field-label">Shipping address</span>
        <textarea
          value={shippingAddress}
          onChange={(e) => setShippingAddress(e.target.value)}
          placeholder="Street, city, postal code, country"
        />
      </label>

      <table className="data-table">
        <thead>
          <tr>
            <th>Item</th>
            <th>Qty</th>
            <th>Price</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item) => {
            const product = products[item.productId];
            return (
              <tr key={item.id}>
                <td>{product?.name ?? item.productId}</td>
                <td>{item.quantity}</td>
                <td>{formatMoney((product?.price ?? 0) * item.quantity)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>

      <div className="row">
        <span>Shipping (flat rate): {formatMoney(FLAT_SHIPPING_FEE)}</span>
      </div>
      <div className="row row-right">
        <span className="total-text">Total: {formatMoney(total)}</span>
      </div>

      {submitError && <p className="error-text">{submitError}</p>}

      <button type="button" className="button button-primary" onClick={handlePay} disabled={submitting}>
        {submitting ? "Redirecting to payment…" : "Pay with card"}
      </button>
    </div>
  );
}
