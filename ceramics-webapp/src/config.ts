// ceramics-api's committed openapi.yaml has no "quote" endpoint to preview a
// shipping fee before an order exists, yet the checkout screen must show the
// flat shipping fee and computed total before the shopper pays (wireframes.dsl
// Checkout screen; PRD story 7 / REQ-007). Per the PRD the fee is flat and
// identical for every order, so it is safe, published business knowledge to
// mirror here for the pre-payment preview — never used to charge: the
// authoritative shippingFee/total always come back from POST /orders and are
// what's shown on OrderConfirmation / order detail views.
export const FLAT_SHIPPING_FEE = 6.0;
