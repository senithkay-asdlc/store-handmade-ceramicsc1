import ballerina/http;
import ballerina/sql;
import ballerina/uuid;

function cartItemRows(string cartId) returns CartItemRow[]|error {
    sql:ParameterizedQuery q = `
        SELECT id, product_id AS "productId", quantity
        FROM cart_items WHERE cart_id = ${cartId}
        ORDER BY id ASC
    `;
    stream<CartItemRow, sql:Error?> rows = dbClient->query(q);
    CartItemRow[] result = [];
    check from CartItemRow row in rows
        do {
            result.push(row);
        };
    return result;
}

function toCart(string cartId, CartItemRow[] rows) returns Cart {
    CartItem[] items = [];
    foreach CartItemRow row in rows {
        items.push({id: row.id, productId: row.productId, quantity: row.quantity});
    }
    return {id: cartId, items};
}

function cartExists(string cartId) returns boolean|error {
    sql:ParameterizedQuery q = `SELECT id FROM carts WHERE id = ${cartId}`;
    record {| string id; |}|sql:Error result = dbClient->queryRow(q);
    if result is sql:NoRowsError {
        return false;
    }
    if result is sql:Error {
        return result;
    }
    return true;
}

function insertCart() returns Cart|error {
    string id = uuid:createType4AsString();
    sql:ParameterizedQuery q = `INSERT INTO carts (id) VALUES (${id})`;
    _ = check dbClient->execute(q);
    return {id, items: []};
}

function loadCart(string cartId) returns Cart|error? {
    boolean|error exists = cartExists(cartId);
    if exists is error {
        return exists;
    }
    if !exists {
        return ();
    }
    CartItemRow[]|error rows = cartItemRows(cartId);
    if rows is error {
        return rows;
    }
    return toCart(cartId, rows);
}

function getProductStock(string productId) returns int?|error {
    sql:ParameterizedQuery q = `SELECT stock_quantity AS "stockQuantity" FROM products WHERE id = ${productId}`;
    record {| int stockQuantity; |}|sql:Error result = dbClient->queryRow(q);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result.stockQuantity;
}

function findCartItemByProduct(string cartId, string productId) returns CartItemRow?|error {
    sql:ParameterizedQuery q = `
        SELECT id, product_id AS "productId", quantity FROM cart_items
        WHERE cart_id = ${cartId} AND product_id = ${productId}
    `;
    CartItemRow|sql:Error result = dbClient->queryRow(q);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result;
}

const string ADD_RESULT_OK = "ok";
const string ADD_RESULT_OUT_OF_STOCK = "out-of-stock";
const string ADD_RESULT_PRODUCT_NOT_FOUND = "product-not-found";
const string ADD_RESULT_INVALID_QUANTITY = "invalid-quantity";

function addCartItemRow(string cartId, CartItemInput input) returns string|error {
    if input.quantity < 1 {
        return ADD_RESULT_INVALID_QUANTITY;
    }
    int?|error stock = getProductStock(input.productId);
    if stock is error {
        return stock;
    }
    if stock is () {
        return ADD_RESULT_PRODUCT_NOT_FOUND;
    }
    int stockQuantity = stock;
    if stockQuantity <= 0 {
        return ADD_RESULT_OUT_OF_STOCK;
    }
    CartItemRow?|error existing = findCartItemByProduct(cartId, input.productId);
    if existing is error {
        return existing;
    }
    if existing is CartItemRow {
        int newQuantity = existing.quantity + input.quantity;
        if newQuantity > stockQuantity {
            return ADD_RESULT_OUT_OF_STOCK;
        }
        sql:ParameterizedQuery q = `UPDATE cart_items SET quantity = ${newQuantity} WHERE id = ${existing.id}`;
        _ = check dbClient->execute(q);
        return ADD_RESULT_OK;
    }
    if input.quantity > stockQuantity {
        return ADD_RESULT_OUT_OF_STOCK;
    }
    string id = uuid:createType4AsString();
    sql:ParameterizedQuery q = `INSERT INTO cart_items (id, cart_id, product_id, quantity) VALUES (${id}, ${cartId}, ${input.productId}, ${input.quantity})`;
    _ = check dbClient->execute(q);
    return ADD_RESULT_OK;
}

function updateCartItemRow(string cartId, string itemId, int quantity) returns boolean|error {
    sql:ParameterizedQuery q = `SELECT id FROM cart_items WHERE id = ${itemId} AND cart_id = ${cartId}`;
    record {| string id; |}|sql:Error existing = dbClient->queryRow(q);
    if existing is sql:NoRowsError {
        return false;
    }
    if existing is sql:Error {
        return existing;
    }
    sql:ParameterizedQuery update = `UPDATE cart_items SET quantity = ${quantity} WHERE id = ${itemId} AND cart_id = ${cartId}`;
    _ = check dbClient->execute(update);
    return true;
}

function removeCartItemRow(string cartId, string itemId) returns boolean|error {
    sql:ParameterizedQuery q = `DELETE FROM cart_items WHERE id = ${itemId} AND cart_id = ${cartId}`;
    sql:ExecutionResult result = check dbClient->execute(q);
    int? affected = result.affectedRowCount;
    return affected is int && affected > 0;
}

service /carts on httpListener {

    resource function post .() returns Cart|http:Created|http:InternalServerError {
        Cart|error cart = insertCart();
        if cart is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to create cart")};
        }
        return <http:Created>{body: cart};
    }

    resource function get [string cartId]() returns Cart|http:NotFound|http:InternalServerError {
        Cart|error? cart = loadCart(cartId);
        if cart is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load cart")};
        }
        if cart is () {
            return notFound("cart not found");
        }
        return cart;
    }

    resource function post [string cartId]/items(CartItemInput payload) returns Cart|http:Created|http:BadRequest|http:NotFound|http:InternalServerError {
        boolean|error exists = cartExists(cartId);
        if exists is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load cart")};
        }
        if !exists {
            return notFound("cart not found");
        }
        string|error addResult = addCartItemRow(cartId, payload);
        if addResult is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to add cart item")};
        }
        if addResult == ADD_RESULT_INVALID_QUANTITY {
            return badRequest("quantity must be at least 1");
        }
        if addResult == ADD_RESULT_PRODUCT_NOT_FOUND {
            return notFound("product not found");
        }
        if addResult == ADD_RESULT_OUT_OF_STOCK {
            return badRequest("product is out of stock");
        }
        Cart|error? cart = loadCart(cartId);
        if cart is error || cart is () {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load cart")};
        }
        return <http:Created>{body: cart};
    }

    resource function patch [string cartId]/items/[string itemId](CartItemQuantityInput payload) returns Cart|http:BadRequest|http:NotFound|http:InternalServerError {
        if payload.quantity < 1 {
            return badRequest("quantity must be at least 1");
        }
        boolean|error exists = cartExists(cartId);
        if exists is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load cart")};
        }
        if !exists {
            return notFound("cart not found");
        }
        boolean|error updated = updateCartItemRow(cartId, itemId, payload.quantity);
        if updated is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to update cart item")};
        }
        if !updated {
            return notFound("cart item not found");
        }
        Cart|error? cart = loadCart(cartId);
        if cart is error || cart is () {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load cart")};
        }
        return cart;
    }

    resource function delete [string cartId]/items/[string itemId]() returns http:NoContent|http:NotFound|http:InternalServerError {
        boolean|error exists = cartExists(cartId);
        if exists is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load cart")};
        }
        if !exists {
            return notFound("cart not found");
        }
        boolean|error removed = removeCartItemRow(cartId, itemId);
        if removed is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to remove cart item")};
        }
        if !removed {
            return notFound("cart item not found");
        }
        return http:NO_CONTENT;
    }
}
