// Store Handmade Ceramics — shopper storefront + admin area

screen Catalog "Shopper browses the ceramics product catalog"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart | Sign in -> SignIn"
  row
    heading "Handmade Ceramics"
    right
    search "Search products…"
  row
    card "Products | 18 | across 4 collections"
    card "Free returns policy | 30 days | on every order"
  heading "All products"
  row
    card "Speckled Stoneware Mug | $28 | In stock" -> ProductDetail
    card "Matte Blue Vase | $54 | In stock" -> ProductDetail
    card "Terracotta Planter | $36 | Out of stock" -> ProductDetail
    card "Hand-thrown Bowl Set | $72 | In stock" -> ProductDetail

screen ProductDetail "Shopper reviews a product before adding it to the cart"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart | Sign in -> SignIn"
  breadcrumb "Catalog / Speckled Stoneware Mug"
  split 60/40
    left
      image "Speckled Stoneware Mug — photo" 400x300
      heading "Speckled Stoneware Mug"
      text "Hand-thrown stoneware mug with a speckled glaze, 12oz capacity."
      badge "In stock" success
    right
      text "$28.00"
      select "Quantity: 1"
      button "Add to cart" primary -> Cart

screen Cart "Shopper reviews cart contents and quantities before checking out"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart | Sign in -> SignIn"
  heading "Your Cart"
  table "Product | Quantity | Price | Subtotal"
    row "Speckled Stoneware Mug | 2 | $28.00 | $56.00"
    row "Matte Blue Vase | 1 | $54.00 | $54.00"
  row
    right
    text "Subtotal: $110.00"
  row
    right
    button "Continue shopping"
    button "Checkout" primary -> Checkout

screen Checkout "Shopper checks out as a guest or signed in, with a flat shipping fee shown"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart | Sign in -> SignIn"
  heading "Checkout"
  row
    card "Sign in for faster checkout" -> SignIn
    card "Continue as guest"
  input "Email (for order confirmation)"
  textarea "Shipping address"
  table "Item | Qty | Price"
    row "Speckled Stoneware Mug | 2 | $56.00"
    row "Matte Blue Vase | 1 | $54.00"
  row
    text "Shipping (flat rate): $6.00"
  row
    right
    text "Total: $116.00"
  button "Pay with card" primary -> OrderConfirmation

screen OrderConfirmation "Shopper sees confirmation that their order was placed"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart | Sign in -> SignIn"
  heading "Order Confirmed"
  badge "Paid" success
  text "Order #10482 — confirmation sent to jane@example.com"
  text "Estimated delivery: 5-7 business days"
  button "Back to shop" -> Catalog

screen SignIn "A shopper or store admin signs in via Thunder SSO"
  navbar "Ceramics Co."
  heading "Sign in"
  text "Continue with your account to check out faster or manage the store."
  button "Sign in with SSO" primary -> Catalog

screen MyOrders "Signed-in shopper views their past orders and status"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart | My Orders -> MyOrders"
  heading "My Orders"
  table "Order | Placed | Total | Status" -> OrderStatusDetail
    row "#10482 | Aug 12 | $116.00 | Paid"
    row "#10391 | Jul 28 | $82.00 | Delivered"

screen OrderStatusDetail "Signed-in shopper checks the status of one order"
  navbar "Ceramics Co. | Shop -> Catalog | Cart -> Cart | My Orders -> MyOrders"
  breadcrumb "My Orders / #10482"
  row
    heading "Order #10482"
    badge "Paid" success
  table "Item | Qty | Price"
    row "Speckled Stoneware Mug | 2 | $56.00"
    row "Matte Blue Vase | 1 | $54.00"
  text "Shipping: $6.00 — Total: $116.00"

screen AdminProducts "Store Admin manages the product catalog"
  navbar "Ceramics Co. Admin"
  sidebar "Products -> AdminProducts | Orders -> AdminOrders | Settings"
  row
    heading "Products"
    right
    button "New product" primary -> AdminProductEdit
  table "Product | Price | Stock | Status" -> AdminProductEdit
    row "Speckled Stoneware Mug | $28.00 | 14 | Active"
    row "Matte Blue Vase | $54.00 | 6 | Active"
    row "Terracotta Planter | $36.00 | 0 | Out of stock"

screen AdminProductEdit "Store Admin creates or edits a product, including stock quantity"
  navbar "Ceramics Co. Admin"
  sidebar "Products -> AdminProducts | Orders -> AdminOrders | Settings"
  breadcrumb "Products / Speckled Stoneware Mug"
  input "Name — e.g. Speckled Stoneware Mug"
  textarea "Description"
  row
    input "Price — 28.00"
    input "Stock quantity — 14"
  image "Product photo" 300x200
  row
    right
    button "Delete product"
    button "Save product" primary -> AdminProducts

screen AdminOrders "Store Admin views incoming orders and updates their status"
  navbar "Ceramics Co. Admin"
  sidebar "Products -> AdminProducts | Orders -> AdminOrders | Settings"
  row
    heading "Orders"
    right
    select "Status: All"
  table "Order | Customer | Total | Status" -> AdminOrderDetail
    row "#10482 | jane@example.com | $116.00 | Paid"
    row "#10391 | Guest | $82.00 | Shipped"
    row "#10375 | mia@example.com | $60.00 | Delivered"

screen AdminOrderDetail "Store Admin reviews one order and updates its status"
  navbar "Ceramics Co. Admin"
  sidebar "Products -> AdminProducts | Orders -> AdminOrders | Settings"
  breadcrumb "Orders / #10482"
  row
    heading "Order #10482"
    badge "Paid" success
  table "Item | Qty | Price"
    row "Speckled Stoneware Mug | 2 | $56.00"
    row "Matte Blue Vase | 1 | $54.00"
  text "Shipping: $6.00 — Total: $116.00"
  row
    select "Update status: Shipped"
    button "Save status" primary -> AdminOrders

flow "Guest checkout"
  description "A shopper browses, carts, and checks out as a guest"
  Catalog
  ProductDetail
  Cart
  Checkout
  OrderConfirmation

flow "Signed-in shopping"
  role "Shopper"
  description "A signed-in shopper checks out and later reviews order history"
  SignIn
  Catalog
  Cart
  Checkout
  OrderConfirmation
  MyOrders
  OrderStatusDetail

flow "Store management"
  role "Store Admin"
  description "The admin manages products, inventory, and order status"
  SignIn
  AdminProducts
  AdminProductEdit
  AdminOrders
  AdminOrderDetail
