import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import * as api from "../../api";

export default function AdminProductEdit() {
  const { productId } = useParams<{ productId: string }>();
  const isNew = !productId || productId === "new";
  const navigate = useNavigate();

  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [stockQuantity, setStockQuantity] = useState("");
  const [photoUrl, setPhotoUrl] = useState("");
  const [loading, setLoading] = useState(!isNew);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    if (isNew || !productId) return;
    api.getProduct(productId).then(({ data, error }) => {
      if (error || !data) {
        setFormError("Could not load this product.");
        return;
      }
      setName(data.name);
      setDescription(data.description ?? "");
      setPrice(String(data.price));
      setStockQuantity(String(data.stockQuantity));
      setPhotoUrl(data.photoUrl ?? "");
      setLoading(false);
    });
  }, [isNew, productId]);

  async function handleSave() {
    setFormError(null);
    const priceNum = Number(price);
    const stockNum = Number(stockQuantity);
    if (!name.trim() || Number.isNaN(priceNum) || Number.isNaN(stockNum)) {
      setFormError("Enter a name, a valid price, and a valid stock quantity.");
      return;
    }
    setSaving(true);
    const input = {
      name: name.trim(),
      description: description.trim() || undefined,
      price: priceNum,
      stockQuantity: stockNum,
      photoUrl: photoUrl.trim() || undefined,
    };
    const { error } = isNew
      ? await api.createProduct(input)
      : await api.updateProduct(productId!, input);
    setSaving(false);
    if (error) {
      setFormError((error as { message?: string }).message ?? "Could not save this product.");
      return;
    }
    navigate("/admin/products");
  }

  async function handleDelete() {
    if (isNew || !productId) return;
    setSaving(true);
    const { error } = await api.deleteProduct(productId);
    setSaving(false);
    if (error) {
      setFormError((error as { message?: string }).message ?? "Could not delete this product.");
      return;
    }
    navigate("/admin/products");
  }

  if (loading) return <div className="page">Loading…</div>;

  return (
    <div className="page">
      <nav className="breadcrumb">
        <Link to="/admin/products">Products</Link> / {isNew ? "New product" : name}
      </nav>
      <h1>{isNew ? "New product" : "Edit product"}</h1>

      <label className="field">
        <span className="field-label">Name</span>
        <input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="e.g. Speckled Stoneware Mug"
        />
      </label>
      <label className="field">
        <span className="field-label">Description</span>
        <textarea value={description} onChange={(e) => setDescription(e.target.value)} />
      </label>
      <div className="row">
        <label className="field">
          <span className="field-label">Price</span>
          <input
            type="number"
            step="0.01"
            min="0"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            placeholder="28.00"
          />
        </label>
        <label className="field">
          <span className="field-label">Stock quantity</span>
          <input
            type="number"
            step="1"
            min="0"
            value={stockQuantity}
            onChange={(e) => setStockQuantity(e.target.value)}
            placeholder="14"
          />
        </label>
      </div>
      <label className="field">
        <span className="field-label">Product photo URL</span>
        <input value={photoUrl} onChange={(e) => setPhotoUrl(e.target.value)} placeholder="https://…" />
      </label>
      {photoUrl ? (
        <img src={photoUrl} alt={name} className="product-photo-preview" />
      ) : (
        <div className="product-photo product-photo-placeholder">Product photo</div>
      )}

      {formError && <p className="error-text">{formError}</p>}

      <div className="row row-right">
        {!isNew && (
          <button type="button" className="button button-danger" onClick={handleDelete} disabled={saving}>
            Delete product
          </button>
        )}
        <button type="button" className="button button-primary" onClick={handleSave} disabled={saving}>
          {saving ? "Saving…" : "Save product"}
        </button>
      </div>
    </div>
  );
}
