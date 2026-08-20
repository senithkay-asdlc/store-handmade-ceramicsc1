# Store Handmade Ceramics — Design

## Overview

A single-seller online store for handmade ceramics. Shoppers use the
`ceramics-webapp` single-page app to browse the product catalog, manage a
cart, and check out — as a guest or signed in via Thunder — paying by card
through a hosted third-party payment checkout, with a flat shipping fee added
at checkout. The same webapp exposes a role-gated admin area where the Store
Admin manages products, tracks inventory, and updates order status. All
business logic and persistence live in the `ceramics-api` service, backed by
`ceramics-db`; the webapp holds no secrets and never talks to the database or
payment provider directly.

## Context (C1)

```mermaid
graph TD
  shopper[Shopper]
  admin[Store Admin]
  system((Store Handmade Ceramics))
  auth[Thunder Auth]
  payment[Payment Provider]

  shopper -->|browses, buys| system
  admin -->|manages catalog & orders| system
  system -->|sign-in / tokens| auth
  system -->|card payment| payment
```

## Domain model (ER)

```mermaid
erDiagram
  CUSTOMER {
    string id
    string email
    string name
  }
  PRODUCT {
    string id
    string name
    string description
    decimal price
    string photoUrl
    int stockQuantity
  }
  CART {
    string id
    string customerId
    string guestSessionId
    datetime createdAt
  }
  CART_ITEM {
    string id
    string cartId
    string productId
    int quantity
  }
  ORDER {
    string id
    string customerId
    string guestEmail
    string status
    decimal shippingFee
    decimal total
    datetime createdAt
  }
  ORDER_ITEM {
    string id
    string orderId
    string productId
    int quantity
    decimal unitPrice
  }

  CUSTOMER ||--o{ CART : "owns (optional)"
  CUSTOMER ||--o{ ORDER : "places (optional)"
  CART ||--o{ CART_ITEM : contains
  CART_ITEM }o--|| PRODUCT : references
  ORDER ||--o{ ORDER_ITEM : contains
  ORDER_ITEM }o--|| PRODUCT : references
```

## Key flows

### Guest checkout

```mermaid
sequenceDiagram
  participant S as Shopper
  participant W as ceramics-webapp
  participant A as ceramics-api
  participant P as Payment Provider

  S->>W: Browse catalog, add products to cart
  W->>A: GET /products, POST /carts/{id}/items
  S->>W: Proceed to checkout as guest
  W->>A: POST /orders (cart, shipping info, guest email)
  A->>A: Apply flat shipping fee, compute total
  A->>P: Create hosted payment checkout
  P-->>S: Shopper completes card payment
  P-->>A: Payment confirmation webhook/callback
  A->>A: Mark order paid
  A-->>W: Order confirmation
  W-->>S: Show order confirmation
```

### Signed-in shopper order history

```mermaid
sequenceDiagram
  participant S as Shopper
  participant W as ceramics-webapp
  participant T as Thunder Auth
  participant A as ceramics-api

  S->>W: Sign in
  W->>T: OIDC + PKCE sign-in
  T-->>W: Token
  S->>W: View my orders
  W->>A: GET /orders?customerId=me (token)
  A->>T: Validate token, resolve customer
  A-->>W: Orders with status
  W-->>S: Show order history
```

### Admin manages catalog, inventory, and order status

```mermaid
sequenceDiagram
  participant M as Store Admin
  participant W as ceramics-webapp
  participant T as Thunder Auth
  participant A as ceramics-api

  M->>W: Sign in to admin area
  W->>T: OIDC + PKCE sign-in
  T-->>W: Token (admin role)
  M->>W: Create/edit product, update stock
  W->>A: POST/PATCH /products (token)
  A->>T: Validate token, resolve admin role
  A-->>W: Updated product
  M->>W: View orders, update status
  W->>A: GET /orders, PATCH /orders/{id}/status
  A-->>W: Updated order
  W-->>M: Reflect new status
```