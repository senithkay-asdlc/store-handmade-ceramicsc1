# Store Handmade Ceramics — PRD

## Problem Statement

A handmade-ceramics maker currently has no dedicated way to sell online: they rely on generic marketplaces or in-person sales, which cap their reach, take a cut of every sale, and give them no control over how their catalog, inventory, or orders are presented and managed. Shoppers looking for handmade ceramics have no single, trustworthy storefront to browse a curated catalog, add pieces to a cart, and check out with confidence.

## Solution

A single-seller online store for handmade ceramics: shoppers browse a product catalog, add items to a cart, and check out — as a guest or signed in — with card payment and flat-rate shipping. The store owner has an admin area to manage products, track inventory, and update order status.

## Actors

- **Shopper** — browses the product catalog, manages a cart, checks out (as a guest or signed in), and can view their own order history when signed in.
- **Store Admin** — manages the product catalog (create/edit/remove products), tracks inventory levels, and views and updates order status.

## User Stories

1. As a Shopper, I want to browse the product catalog, so that I can discover handmade ceramics available for purchase.
2. As a Shopper, I want to view a product's details (photos, description, price, stock availability), so that I can decide whether to buy it.
3. As a Shopper, I want to add products to a cart and adjust quantities, so that I can collect items before purchasing.
4. As a Shopper, I want to check out as a guest, so that I can complete a purchase without creating an account.
5. As a Shopper, I want to sign in via SSO, so that I can check out with my account and later view my order history.
6. As a Shopper, I want to pay by card through a hosted payment checkout, so that I can complete my purchase securely.
7. As a Shopper, I want to see a flat shipping fee applied at checkout, so that I know the total cost before I pay.
8. As a Shopper, I want to receive confirmation that my order was placed, so that I know my purchase succeeded.
9. As a signed-in Shopper, I want to view my past orders and their status, so that I can track my purchases.
10. As a Store Admin, I want to sign in via SSO to a protected admin area, so that only I can manage the store.
11. As a Store Admin, I want to create, edit, and remove products in the catalog, so that I can keep my offerings current.
12. As a Store Admin, I want to track inventory levels per product, so that out-of-stock items stop being sold.
13. As a Store Admin, I want to view incoming orders and update their status (e.g. paid, shipped, delivered), so that I can fulfill purchases and keep shoppers informed.

## Product Decisions

- Single-seller store: one ceramics business owns the entire catalog; there is no multi-vendor/marketplace support.
- Every user (Shopper and Store Admin) signs in via SSO through Thunder, the platform IDP, when they choose to sign in.
- Guest checkout is allowed: an account is optional for purchasing, but required to view order history.
- Payments are processed via a hosted, third-party card-payment checkout provider; PCI compliance stays with that provider.
- Shipping is a flat rate applied to every order; no weight- or destination-based shipping calculation.
- The Store Admin area provides basic catalog management (create/edit/remove products), inventory tracking, and order status management.

## Out of Scope

- Multi-vendor/marketplace support (multiple independent sellers).
- Calculated or destination/weight-based shipping rates.
- Product reviews/ratings, wishlists, and promotional discounts/coupons.
- Returns/refunds handling beyond order status tracking.
- Multi-currency or international tax handling.

## Open Questions

None at this time.