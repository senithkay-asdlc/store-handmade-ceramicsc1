import { BrowserRouter, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import { CartProvider } from "./context/CartContext";
import ShopLayout from "./components/ShopLayout";
import AdminLayout from "./components/AdminLayout";
import RequireAuth from "./components/RequireAuth";
import RequireAdmin from "./components/RequireAdmin";

import Catalog from "./pages/Catalog";
import ProductDetail from "./pages/ProductDetail";
import Cart from "./pages/Cart";
import Checkout from "./pages/Checkout";
import OrderConfirmation from "./pages/OrderConfirmation";
import SignIn from "./pages/SignIn";
import Callback from "./pages/Callback";
import MyOrders from "./pages/MyOrders";
import OrderStatusDetail from "./pages/OrderStatusDetail";

import AdminProducts from "./pages/admin/AdminProducts";
import AdminProductEdit from "./pages/admin/AdminProductEdit";
import AdminOrders from "./pages/admin/AdminOrders";
import AdminOrderDetail from "./pages/admin/AdminOrderDetail";

export default function App() {
  return (
    <AuthProvider>
      <CartProvider>
        <BrowserRouter>
          <Routes>
            {/* /callback and /signin render standalone (their own SignIn-style
                navbar per wireframes.dsl), everything else shares the shop chrome. */}
            <Route path="/callback" element={<Callback />} />

            <Route element={<ShopLayout />}>
              <Route path="/" element={<Catalog />} />
              <Route path="/products/:productId" element={<ProductDetail />} />
              <Route path="/cart" element={<Cart />} />
              <Route path="/checkout" element={<Checkout />} />
              <Route path="/order-confirmation/:orderId" element={<OrderConfirmation />} />
              <Route path="/order-confirmation" element={<OrderConfirmation />} />
              <Route path="/signin" element={<SignIn />} />
              <Route
                path="/my-orders"
                element={
                  <RequireAuth>
                    <MyOrders />
                  </RequireAuth>
                }
              />
              <Route
                path="/my-orders/:orderId"
                element={
                  <RequireAuth>
                    <OrderStatusDetail />
                  </RequireAuth>
                }
              />
            </Route>

            <Route
              path="/admin"
              element={
                <RequireAdmin>
                  <AdminLayout />
                </RequireAdmin>
              }
            >
              <Route path="products" element={<AdminProducts />} />
              <Route path="products/new" element={<AdminProductEdit />} />
              <Route path="products/:productId" element={<AdminProductEdit />} />
              <Route path="orders" element={<AdminOrders />} />
              <Route path="orders/:orderId" element={<AdminOrderDetail />} />
            </Route>

            <Route path="*" element={<Catalog />} />
          </Routes>
        </BrowserRouter>
      </CartProvider>
    </AuthProvider>
  );
}
