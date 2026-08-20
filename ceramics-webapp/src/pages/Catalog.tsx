import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import * as api from "../api";
import type { Product } from "../api";
import { formatMoney } from "../format";

export default function Catalog() {
  const [products, setProducts] = useState<Product[]>([]);
  const [count, setCount] = useState(0);
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    api
      .listProducts(100, 0)
      .then(({ data, error }) => {
        if (cancelled) return;
        if (error) {
          setLoadError("Could not load the catalog. Please try again.");
          return;
        }
        setProducts(data?.data ?? []);
        setCount(data?.count ?? 0);
      })
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, []);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return products;
    return products.filter((p) => p.name.toLowerCase().includes(q));
  }, [products, query]);

  return (
    <div className="page">
      <div className="row row-between">
        <h1>Handmade Ceramics</h1>
        <input
          className="search-input"
          placeholder="Search products…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>

      <div className="row">
        <div className="stat-card">
          <div className="stat-label">Products</div>
          <div className="stat-value">{count}</div>
          <div className="stat-caption">available in the catalog</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Free returns policy</div>
          <div className="stat-value">30 days</div>
          <div className="stat-caption">on every order</div>
        </div>
      </div>

      <h2>All products</h2>
      {loading && <p>Loading products…</p>}
      {loadError && <p className="error-text">{loadError}</p>}
      {!loading && !loadError && visible.length === 0 && <p>No products match your search.</p>}

      <div className="product-grid">
        {visible.map((product) => (
          <Link to={`/products/${product.id}`} key={product.id} className="product-card">
            <div className="product-card-name">{product.name}</div>
            <div className="product-card-price">{formatMoney(product.price)}</div>
            <span className={`badge ${product.stockQuantity > 0 ? "badge-success" : "badge-muted"}`}>
              {product.stockQuantity > 0 ? "In stock" : "Out of stock"}
            </span>
          </Link>
        ))}
      </div>
    </div>
  );
}
