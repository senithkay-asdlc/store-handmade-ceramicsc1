import { Outlet } from "react-router-dom";
import Navbar from "./Navbar";

export default function ShopLayout() {
  return (
    <div className="shop-shell">
      <Navbar />
      <main className="shop-content">
        <Outlet />
      </main>
    </div>
  );
}
