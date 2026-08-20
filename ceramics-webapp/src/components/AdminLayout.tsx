import { NavLink, Outlet } from "react-router-dom";

export default function AdminLayout() {
  return (
    <div className="admin-shell">
      <nav className="navbar">
        <div className="navbar-brand">Ceramics Co. Admin</div>
      </nav>
      <div className="admin-body">
        <aside className="sidebar">
          <NavLink to="/admin/products" className={navClass}>
            Products
          </NavLink>
          <NavLink to="/admin/orders" className={navClass}>
            Orders
          </NavLink>
          <span className="sidebar-item sidebar-item-inert">Settings</span>
        </aside>
        <main className="admin-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

function navClass({ isActive }: { isActive: boolean }) {
  return isActive ? "sidebar-item sidebar-item-active" : "sidebar-item";
}
