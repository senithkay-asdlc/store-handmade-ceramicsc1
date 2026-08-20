// Wire-facing records - shaped to mirror specs/design/components/ceramics-api/openapi.yaml exactly.

public type ErrorPayload record {|
    int code;
    string message;
    string description?;
    string moreInfo?;
|};

public type Product record {|
    string id;
    string name;
    string description?;
    decimal price;
    string photoUrl?;
    int stockQuantity;
|};

public type ProductInput record {|
    string name;
    string description?;
    decimal price;
    string photoUrl?;
    int stockQuantity;
|};

public type ProductPage record {|
    int count;
    string? next;
    string? previous;
    Product[] data;
|};

public type CartItem record {|
    string id;
    string productId;
    int quantity;
|};

public type Cart record {|
    string id;
    CartItem[] items;
|};

public type CartItemInput record {|
    string productId;
    int quantity;
|};

public type CartItemQuantityInput record {|
    int quantity;
|};

public type OrderItem record {|
    string productId;
    int quantity;
    decimal unitPrice;
|};

public type Order record {|
    string id;
    string? customerId;
    string? guestEmail;
    string status;
    decimal shippingFee;
    decimal total;
    string createdAt;
    OrderItem[] items;
    // Not part of the documented schema; additional properties are allowed
    // by the OpenAPI Order schema (no additionalProperties: false) and this
    // is how the shopper is handed the hosted Stripe Checkout redirect right
    // after an order is created.
    string checkoutUrl?;
|};

public type OrderPage record {|
    int count;
    string? next;
    string? previous;
    Order[] data;
|};

public type OrderInput record {|
    string cartId;
    string guestEmail?;
    string shippingAddress?;
|};

public type OrderStatusInput record {|
    string status;
|};

// Internal DB row shapes - column-aliased query results, converted to the
// wire records above so a NULL column never leaks into a non-nullable field.

type ProductRow record {|
    string id;
    string name;
    string? description;
    decimal price;
    string? photoUrl;
    int stockQuantity;
|};

type CartItemRow record {|
    string id;
    string productId;
    int quantity;
|};

type OrderRow record {|
    string id;
    string? customerId;
    string? guestEmail;
    string status;
    decimal shippingFee;
    decimal total;
    string createdAt;
|};

type OrderItemRow record {|
    string productId;
    int quantity;
    decimal unitPrice;
|};

const string ROLE_STORE_ADMIN = "store-admin";
const string ORDER_STATUS_PENDING = "pending";
const string ORDER_STATUS_PAID = "paid";
const string ORDER_STATUS_SHIPPED = "shipped";
const string ORDER_STATUS_DELIVERED = "delivered";
const string ORDER_STATUS_CANCELLED = "cancelled";

final string[] & readonly VALID_ORDER_STATUSES = [
    ORDER_STATUS_PENDING,
    ORDER_STATUS_PAID,
    ORDER_STATUS_SHIPPED,
    ORDER_STATUS_DELIVERED,
    ORDER_STATUS_CANCELLED
];
