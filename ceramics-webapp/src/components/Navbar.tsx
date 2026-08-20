import { Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { displayName } from "../auth";

export default function Navbar() {
  const { isSignedIn, isStoreAdmin, user, signOut } = useAuth();
  const { itemCount } = useCart();

  return (
    <nav className="navbar">
      <div className="navbar-brand">
        <Link to="/">Ceramics Co.</Link>
      </div>
      <div className="navbar-links">
        <Link to="/">Shop</Link>
        <Link to="/cart">Cart{itemCount > 0 ? ` (${itemCount})` : ""}</Link>
        {isSignedIn && <Link to="/my-orders">My Orders</Link>}
        {isStoreAdmin && (
          <Link to="/admin/products" className="navbar-admin-link">
            Admin
          </Link>
        )}
        {isSignedIn ? (
          <span className="navbar-account">
            <span className="navbar-account-name">{displayName(user)}</span>
            <button type="button" onClick={() => signOut()} className="link-button">
              Sign out
            </button>
          </span>
        ) : (
          <Link to="/signin">Sign in</Link>
        )}
      </div>
    </nav>
  );
}
