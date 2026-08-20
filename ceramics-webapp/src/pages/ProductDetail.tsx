import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import * as api from "../api";
import type { Product } from "../api";
import { useCart } from "../context/CartContext";
import { formatMoney } from "../format";

export default function ProductDetail() {
  const { productId } = useParams<{ productId: string }>();
  const navigate = useNavigate();
  const { addItem, error: cartError, clearError } = useCart();
  const [product, setProduct] = useState<Product | null>(null);
  const [notFound, setNotFound] = useState(false);
  const [quantity, setQuantity] = useState(1);
  const [adding, setAdding] = useState(false);

  useEffect(() => {
    if (!productId) return;
    clearError();
    api.getProduct(productId).then(({ data, error }) => {
      if (error || !data) {
        setNotFound(true);
        return;
      }
      setProduct(data);
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [productId]);

  if (notFound) {
    return (
      <div className="page">
        <p>Product not found.</p>
        <Link to="/">Back to shop</Link>
      </div>
    );
  }

  if (!product) return <div className="page">Loading…</div>;

  const inStock = product.stockQuantity > 0;

  async function handleAddToCart() {
    setAdding(true);
    const ok = await addItem(product!.id, quantity);
    setAdding(false);
    if (ok) navigate("/cart");
  }

  return (
    <div className="page">
      <nav className="breadcrumb">
        <Link to="/">Catalog</Link> / {product.name}
      </nav>
      <div className="split">
        <div className="split-left">
          {product.photoUrl ? (
            <img src={product.photoUrl} alt={product.name} className="product-photo" />
          ) : (
            <div className="product-photo product-photo-placeholder">No photo available</div>
          )}
          <h1>{product.name}</h1>
          <p>{product.description || "No description provided."}</p>
          <span className={`badge ${inStock ? "badge-success" : "badge-muted"}`}>
            {inStock ? "In stock" : "Out of stock"}
          </span>
        </div>
        <div className="split-right">
          <div className="price">{formatMoney(product.price)}</div>
          {inStock ? (
            <>
              <label className="field-label" htmlFor="quantity">
                Quantity
              </label>
              <select
                id="quantity"
                value={quantity}
                onChange={(e) => setQuantity(Number(e.target.value))}
                disabled={!inStock}
              >
                {Array.from({ length: Math.min(product.stockQuantity, 10) }, (_, i) => i + 1).map((n) => (
                  <option key={n} value={n}>
                    {n}
                  </option>
                ))}
              </select>
              <button
                type="button"
                className="button button-primary"
                onClick={handleAddToCart}
                disabled={adding}
              >
                {adding ? "Adding…" : "Add to cart"}
              </button>
            </>
          ) : (
            <button type="button" className="button" disabled>
              Out of stock
            </button>
          )}
          {cartError && <p className="error-text">{cartError}</p>}
        </div>
      </div>
    </div>
  );
}
