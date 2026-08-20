import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerina/uuid;

type CheckoutItem record {|
    string productId;
    string productName;
    decimal unitPrice;
    int quantity;
    int stockQuantity;
|};

function isValidOrderStatus(string status) returns boolean {
    foreach string candidate in VALID_ORDER_STATUSES {
        if candidate == status {
            return true;
        }
    }
    return false;
}

function loadCheckoutItems(string cartId) returns CheckoutItem[]|error {
    sql:ParameterizedQuery q = `
        SELECT ci.product_id AS "productId", p.name AS "productName", p.price AS "unitPrice",
               ci.quantity AS "quantity", p.stock_quantity AS "stockQuantity"
        FROM cart_items ci
        JOIN products p ON p.id = ci.product_id
        WHERE ci.cart_id = ${cartId}
    `;
    stream<CheckoutItem, sql:Error?> rows = dbClient->query(q);
    CheckoutItem[] result = [];
    check from CheckoutItem row in rows
        do {
            result.push(row);
        };
    return result;
}

function insertOrder(string? customerId, string? guestEmail, decimal shippingFee, decimal total, string? shippingAddress) returns string|error {
    string id = uuid:createType4AsString();
    sql:ParameterizedQuery q = `
        INSERT INTO orders (id, customer_id, guest_email, status, shipping_fee, total, shipping_address)
        VALUES (${id}, ${customerId}, ${guestEmail}, ${ORDER_STATUS_PENDING}, ${shippingFee}, ${total}, ${shippingAddress})
    `;
    _ = check dbClient->execute(q);
    return id;
}

function insertOrderItem(string orderId, string productId, int quantity, decimal unitPrice) returns error? {
    string id = uuid:createType4AsString();
    sql:ParameterizedQuery q = `
        INSERT INTO order_items (id, order_id, product_id, quantity, unit_price)
        VALUES (${id}, ${orderId}, ${productId}, ${quantity}, ${unitPrice})
    `;
    _ = check dbClient->execute(q);
}

function insertOrderStatusHistory(string orderId, string status) returns error? {
    string id = uuid:createType4AsString();
    sql:ParameterizedQuery q = `INSERT INTO order_status_history (id, order_id, status) VALUES (${id}, ${orderId}, ${status})`;
    _ = check dbClient->execute(q);
}

function setOrderStripeSession(string orderId, string sessionId) returns error? {
    sql:ParameterizedQuery q = `UPDATE orders SET stripe_session_id = ${sessionId} WHERE id = ${orderId}`;
    _ = check dbClient->execute(q);
}

function deleteOrder(string orderId) returns error? {
    sql:ParameterizedQuery q = `DELETE FROM orders WHERE id = ${orderId}`;
    _ = check dbClient->execute(q);
}

function updateOrderStatusRow(string orderId, string status) returns error? {
    sql:ParameterizedQuery q = `UPDATE orders SET status = ${status} WHERE id = ${orderId}`;
    _ = check dbClient->execute(q);
}

function orderRow(string orderId) returns OrderRow|error? {
    sql:ParameterizedQuery q = `
        SELECT id, customer_id AS "customerId", guest_email AS "guestEmail", status,
               shipping_fee AS "shippingFee", total,
               to_char(created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS "createdAt"
        FROM orders WHERE id = ${orderId}
    `;
    OrderRow|sql:Error result = dbClient->queryRow(q);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result;
}

function orderItemRows(string orderId) returns OrderItemRow[]|error {
    sql:ParameterizedQuery q = `
        SELECT product_id AS "productId", quantity, unit_price AS "unitPrice"
        FROM order_items WHERE order_id = ${orderId} ORDER BY id ASC
    `;
    stream<OrderItemRow, sql:Error?> rows = dbClient->query(q);
    OrderItemRow[] result = [];
    check from OrderItemRow row in rows
        do {
            result.push(row);
        };
    return result;
}

function toOrder(OrderRow row, OrderItemRow[] itemRows) returns Order {
    OrderItem[] items = [];
    foreach OrderItemRow itemRow in itemRows {
        items.push({productId: itemRow.productId, quantity: itemRow.quantity, unitPrice: itemRow.unitPrice});
    }
    return {
        id: row.id,
        customerId: row.customerId,
        guestEmail: row.guestEmail,
        status: row.status,
        shippingFee: row.shippingFee,
        total: row.total,
        createdAt: row.createdAt,
        items
    };
}

function loadOrder(string orderId) returns Order|error? {
    OrderRow|error? row = orderRow(orderId);
    if row is error {
        return row;
    }
    if row is () {
        return ();
    }
    OrderItemRow[]|error itemRows = orderItemRows(orderId);
    if itemRows is error {
        return itemRows;
    }
    return toOrder(row, itemRows);
}

function countOrders(string? customerId, boolean isAdmin, string? status) returns int|error {
    sql:ParameterizedQuery q = `SELECT count(*) AS c FROM orders WHERE 1 = 1`;
    if !isAdmin {
        q = sql:queryConcat(q, ` AND customer_id = ${customerId}`);
    }
    if status is string {
        q = sql:queryConcat(q, ` AND status = ${status}`);
    }
    record {| int c; |} result = check dbClient->queryRow(q);
    return result.c;
}

function listOrderRows(string? customerId, boolean isAdmin, string? status, int 'limit, int offset) returns OrderRow[]|error {
    sql:ParameterizedQuery q = `
        SELECT id, customer_id AS "customerId", guest_email AS "guestEmail", status,
               shipping_fee AS "shippingFee", total,
               to_char(created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS "createdAt"
        FROM orders WHERE 1 = 1
    `;
    if !isAdmin {
        q = sql:queryConcat(q, ` AND customer_id = ${customerId}`);
    }
    if status is string {
        q = sql:queryConcat(q, ` AND status = ${status}`);
    }
    q = sql:queryConcat(q, ` ORDER BY created_at DESC LIMIT ${'limit} OFFSET ${offset}`);
    stream<OrderRow, sql:Error?> rows = dbClient->query(q);
    OrderRow[] result = [];
    check from OrderRow row in rows
        do {
            result.push(row);
        };
    return result;
}

function ordersPageUri(int 'limit, int offset, string? status) returns string {
    string uri = "/orders?limit=" + 'limit.toString() + "&offset=" + offset.toString();
    if status is string {
        uri = uri + "&status=" + status;
    }
    return uri;
}

function findOrderIdBySessionId(string sessionId) returns string?|error {
    sql:ParameterizedQuery q = `SELECT id FROM orders WHERE stripe_session_id = ${sessionId}`;
    record {| string id; |}|sql:Error result = dbClient->queryRow(q);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result.id;
}

function markOrderPaid(string orderId) returns error? {
    sql:ParameterizedQuery q = `UPDATE orders SET status = ${ORDER_STATUS_PAID} WHERE id = ${orderId} AND status != ${ORDER_STATUS_PAID}`;
    sql:ExecutionResult result = check dbClient->execute(q);
    int? affected = result.affectedRowCount;
    if affected is int && affected > 0 {
        check insertOrderStatusHistory(orderId, ORDER_STATUS_PAID);
    }
}

service /orders on httpListener {

    resource function get .(@http:Header {name: "X-User-Id"} string? x\-user\-id, @http:Header {name: "X-User-Groups"} string? x\-user\-groups, int 'limit = 20, int offset = 0, string? status = ()) returns OrderPage|http:Unauthorized|http:InternalServerError {
        if x\-user\-id is () {
            return unauthorized("missing or invalid token");
        }
        string callerId = x\-user\-id;
        boolean admin = isStoreAdmin(x\-user\-groups);
        string? scopeCustomerId = admin ? () : callerId;
        int effectiveLimit = 'limit > 100 ? 100 : ('limit < 1 ? 20 : 'limit);
        int effectiveOffset = offset < 0 ? 0 : offset;
        string? statusFilter = status is string && isValidOrderStatus(status) ? status : ();

        int|error count = countOrders(scopeCustomerId, admin, statusFilter);
        if count is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to list orders")};
        }
        OrderRow[]|error rows = listOrderRows(scopeCustomerId, admin, statusFilter, effectiveLimit, effectiveOffset);
        if rows is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to list orders")};
        }
        Order[] orders = [];
        foreach OrderRow row in rows {
            OrderItemRow[]|error itemRows = orderItemRows(row.id);
            if itemRows is error {
                return <http:InternalServerError>{body: errorPayload(500, "failed to list orders")};
            }
            orders.push(toOrder(row, itemRows));
        }
        string? next = effectiveOffset + effectiveLimit < count ? ordersPageUri(effectiveLimit, effectiveOffset + effectiveLimit, statusFilter) : ();
        int previousOffset = effectiveOffset - effectiveLimit > 0 ? effectiveOffset - effectiveLimit : 0;
        string? previous = effectiveOffset > 0 ? ordersPageUri(effectiveLimit, previousOffset, statusFilter) : ();
        return {count, next, previous, data: orders};
    }

    resource function post .(@http:Header {name: "X-User-Id"} string? x\-user\-id, OrderInput payload) returns Order|http:Created|http:BadRequest|http:NotFound|http:InternalServerError {
        string? customerId = x\-user\-id;
        string? guestEmail = ();
        if customerId is () {
            string? inputEmail = payload?.guestEmail;
            if inputEmail is () {
                return badRequest("guestEmail is required for guest checkout");
            }
            if inputEmail.trim() == "" {
                return badRequest("guestEmail is required for guest checkout");
            }
            guestEmail = inputEmail;
        }

        boolean|error exists = cartExists(payload.cartId);
        if exists is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load cart")};
        }
        if !exists {
            return notFound("cart not found");
        }

        CheckoutItem[]|error items = loadCheckoutItems(payload.cartId);
        if items is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load cart")};
        }
        if items.length() == 0 {
            return badRequest("cart is empty");
        }
        foreach CheckoutItem item in items {
            if item.stockQuantity < item.quantity {
                return badRequest("cart item is out of stock");
            }
        }

        decimal subtotal = 0d;
        foreach CheckoutItem item in items {
            subtotal += item.unitPrice * <decimal>item.quantity;
        }
        decimal total = subtotal + flatShippingFee;

        string|error orderId = insertOrder(customerId, guestEmail, flatShippingFee, total, payload?.shippingAddress);
        if orderId is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to create order")};
        }
        string oid = orderId;

        foreach CheckoutItem item in items {
            error? insErr = insertOrderItem(oid, item.productId, item.quantity, item.unitPrice);
            if insErr is error {
                error? deleteErr = deleteOrder(oid);
                if deleteErr is error {
                    log:printError("failed to clean up order after error", 'error = deleteErr, orderId = oid);
                }
                return <http:InternalServerError>{body: errorPayload(500, "failed to create order")};
            }
        }
        error? histErr = insertOrderStatusHistory(oid, ORDER_STATUS_PENDING);
        if histErr is error {
            error? deleteErr = deleteOrder(oid);
            if deleteErr is error {
                log:printError("failed to clean up order after error", 'error = deleteErr, orderId = oid);
            }
            return <http:InternalServerError>{body: errorPayload(500, "failed to create order")};
        }

        CheckoutLineItem[] lineItems = [];
        foreach CheckoutItem item in items {
            lineItems.push({name: item.productName, unitAmountCents: toCents(item.unitPrice), quantity: item.quantity});
        }
        CheckoutSession|error session = createCheckoutSession(oid, lineItems, flatShippingFee, guestEmail);
        if session is error {
            log:printError("stripe checkout session creation failed", 'error = session, orderId = oid);
            error? deleteErr = deleteOrder(oid);
            if deleteErr is error {
                log:printError("failed to clean up order after error", 'error = deleteErr, orderId = oid);
            }
            return <http:InternalServerError>{body: errorPayload(500, "failed to start payment checkout")};
        }
        error? sessionErr = setOrderStripeSession(oid, session.sessionId);
        if sessionErr is error {
            log:printError("failed to persist stripe session id", orderId = oid);
        }

        Order|error? created = loadOrder(oid);
        if created is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load created order")};
        }
        if created is () {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load created order")};
        }
        Order result = created;
        result.checkoutUrl = session.url;
        return <http:Created>{body: result};
    }

    resource function get [string orderId](@http:Header {name: "X-User-Id"} string? x\-user\-id, @http:Header {name: "X-User-Groups"} string? x\-user\-groups) returns Order|http:Forbidden|http:NotFound|http:InternalServerError {
        Order|error? loaded = loadOrder(orderId);
        if loaded is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load order")};
        }
        if loaded is () {
            return notFound("order not found");
        }
        Order ord = loaded;
        boolean admin = isStoreAdmin(x\-user\-groups);
        string? orderCustomerId = ord.customerId;
        if !admin && orderCustomerId is string {
            if x\-user\-id is () || x\-user\-id != orderCustomerId {
                return forbidden("caller may not view this order");
            }
        }
        return ord;
    }

    resource function patch [string orderId]/status(@http:Header {name: "X-User-Id"} string? x\-user\-id, @http:Header {name: "X-User-Groups"} string? x\-user\-groups, OrderStatusInput payload) returns Order|http:BadRequest|http:Unauthorized|http:Forbidden|http:NotFound|http:InternalServerError {
        if x\-user\-id is () {
            return unauthorized("missing or invalid token");
        }
        if !isStoreAdmin(x\-user\-groups) {
            return forbidden("caller is not a Store Admin");
        }
        if !isValidOrderStatus(payload.status) {
            return badRequest("invalid status transition");
        }
        Order|error? existing = loadOrder(orderId);
        if existing is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to update order status")};
        }
        if existing is () {
            return notFound("order not found");
        }
        error? updateErr = updateOrderStatusRow(orderId, payload.status);
        if updateErr is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to update order status")};
        }
        error? histErr = insertOrderStatusHistory(orderId, payload.status);
        if histErr is error {
            log:printError("failed to record order status history", orderId = orderId);
        }
        Order|error? updated = loadOrder(orderId);
        if updated is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to update order status")};
        }
        if updated is () {
            return notFound("order not found");
        }
        return updated;
    }
}
