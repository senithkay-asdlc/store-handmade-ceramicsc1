import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import * as api from "../../api";
import type { Product } from "../../api";
import { formatMoney } from "../../format";

export default function AdminProducts() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  function load() {
    setLoading(true);
    api
      .listProducts(100, 0)
      .then(({ data, error }) => {
        if (error) {
          setLoadError("Could not load products.");
          return;
        }
        setProducts(data?.data ?? []);
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, []);

  return (
    <div className="page">
      <div className="row row-between">
        <h1>Products</h1>
        <Link to="/admin/products/new" className="button button-primary">
          New product
        </Link>
      </div>
      {loading && <p>Loading products…</p>}
      {loadError && <p className="error-text">{loadError}</p>}
      {!loading && !loadError && (
        <table className="data-table">
          <thead>
            <tr>
              <th>Product</th>
              <th>Price</th>
              <th>Stock</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {products.map((product) => (
              <tr key={product.id}>
                <td>
                  <Link to={`/admin/products/${product.id}`}>{product.name}</Link>
                </td>
                <td>{formatMoney(product.price)}</td>
                <td>{product.stockQuantity}</td>
                <td>
                  <span className={`badge ${product.stockQuantity > 0 ? "badge-success" : "badge-muted"}`}>
                    {product.stockQuantity > 0 ? "Active" : "Out of stock"}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
