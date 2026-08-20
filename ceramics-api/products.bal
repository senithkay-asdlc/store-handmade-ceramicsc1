import ballerina/http;
import ballerina/sql;
import ballerina/uuid;

function toProduct(ProductRow row) returns Product {
    Product product = {
        id: row.id,
        name: row.name,
        price: row.price,
        stockQuantity: row.stockQuantity
    };
    string? description = row.description;
    if description is string {
        product.description = description;
    }
    string? photoUrl = row.photoUrl;
    if photoUrl is string {
        product.photoUrl = photoUrl;
    }
    return product;
}

function countProducts() returns int|error {
    sql:ParameterizedQuery q = `SELECT count(*) AS c FROM products`;
    record {| int c; |} result = check dbClient->queryRow(q);
    return result.c;
}

function listProductRows(int 'limit, int offset) returns Product[]|error {
    sql:ParameterizedQuery q = `
        SELECT id, name, description, price, photo_url AS "photoUrl", stock_quantity AS "stockQuantity"
        FROM products
        ORDER BY created_at ASC
        LIMIT ${'limit} OFFSET ${offset}
    `;
    stream<ProductRow, sql:Error?> rows = dbClient->query(q);
    Product[] products = [];
    check from ProductRow row in rows
        do {
            products.push(toProduct(row));
        };
    return products;
}

function getProductRow(string productId) returns ProductRow|error? {
    sql:ParameterizedQuery q = `
        SELECT id, name, description, price, photo_url AS "photoUrl", stock_quantity AS "stockQuantity"
        FROM products WHERE id = ${productId}
    `;
    ProductRow|sql:Error result = dbClient->queryRow(q);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return result;
}

function insertProduct(ProductInput input) returns Product|error {
    string id = uuid:createType4AsString();
    string? description = input?.description;
    string? photoUrl = input?.photoUrl;
    sql:ParameterizedQuery q = `
        INSERT INTO products (id, name, description, price, photo_url, stock_quantity)
        VALUES (${id}, ${input.name}, ${description}, ${input.price}, ${photoUrl}, ${input.stockQuantity})
    `;
    _ = check dbClient->execute(q);
    ProductRow|error? row = getProductRow(id);
    if row is ProductRow {
        return toProduct(row);
    }
    return error("failed to load product after insert");
}

function updateProductRow(string productId, ProductInput input) returns Product|error? {
    ProductRow|error? existing = getProductRow(productId);
    if existing is error {
        return existing;
    }
    if existing is () {
        return ();
    }
    string? description = input?.description;
    string? photoUrl = input?.photoUrl;
    sql:ParameterizedQuery q = `
        UPDATE products
        SET name = ${input.name}, description = ${description}, price = ${input.price},
            photo_url = ${photoUrl}, stock_quantity = ${input.stockQuantity}
        WHERE id = ${productId}
    `;
    _ = check dbClient->execute(q);
    ProductRow|error? row = getProductRow(productId);
    if row is ProductRow {
        return toProduct(row);
    }
    return ();
}

function deleteProductRow(string productId) returns boolean|error {
    sql:ParameterizedQuery q = `DELETE FROM products WHERE id = ${productId}`;
    sql:ExecutionResult result = check dbClient->execute(q);
    int? affected = result.affectedRowCount;
    return affected is int && affected > 0;
}

function productPageUri(int 'limit, int offset) returns string {
    return "/products?limit=" + 'limit.toString() + "&offset=" + offset.toString();
}

service /products on httpListener {

    resource function get .(int 'limit = 20, int offset = 0) returns ProductPage|http:InternalServerError {
        int effectiveLimit = 'limit > 100 ? 100 : ('limit < 1 ? 20 : 'limit);
        int effectiveOffset = offset < 0 ? 0 : offset;
        int|error count = countProducts();
        if count is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to list products")};
        }
        Product[]|error products = listProductRows(effectiveLimit, effectiveOffset);
        if products is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to list products")};
        }
        string? next = effectiveOffset + effectiveLimit < count ? productPageUri(effectiveLimit, effectiveOffset + effectiveLimit) : ();
        string? previous = effectiveOffset > 0 ? productPageUri(effectiveLimit, effectiveOffset - effectiveLimit > 0 ? effectiveOffset - effectiveLimit : 0) : ();
        return {count, next, previous, data: products};
    }

    resource function post .(@http:Header {name: "X-User-Id"} string? x\-user\-id, @http:Header {name: "X-User-Groups"} string? x\-user\-groups, ProductInput payload) returns Product|http:Created|http:BadRequest|http:Unauthorized|http:Forbidden|http:InternalServerError {
        if x\-user\-id is () {
            return unauthorized("missing or invalid token");
        }
        if !isStoreAdmin(x\-user\-groups) {
            return forbidden("caller is not a Store Admin");
        }
        if payload.name.trim() == "" || payload.price < 0d || payload.stockQuantity < 0 {
            return badRequest("invalid product input");
        }
        Product|error created = insertProduct(payload);
        if created is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to create product")};
        }
        return <http:Created>{body: created};
    }

    resource function get [string productId]() returns Product|http:NotFound|http:InternalServerError {
        ProductRow|error? row = getProductRow(productId);
        if row is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to load product")};
        }
        if row is () {
            return notFound("product not found");
        }
        return toProduct(row);
    }

    resource function patch [string productId](@http:Header {name: "X-User-Id"} string? x\-user\-id, @http:Header {name: "X-User-Groups"} string? x\-user\-groups, ProductInput payload) returns Product|http:BadRequest|http:Unauthorized|http:Forbidden|http:NotFound|http:InternalServerError {
        if x\-user\-id is () {
            return unauthorized("missing or invalid token");
        }
        if !isStoreAdmin(x\-user\-groups) {
            return forbidden("caller is not a Store Admin");
        }
        if payload.name.trim() == "" || payload.price < 0d || payload.stockQuantity < 0 {
            return badRequest("invalid product input");
        }
        Product|error? updated = updateProductRow(productId, payload);
        if updated is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to update product")};
        }
        if updated is () {
            return notFound("product not found");
        }
        return updated;
    }

    resource function delete [string productId](@http:Header {name: "X-User-Id"} string? x\-user\-id, @http:Header {name: "X-User-Groups"} string? x\-user\-groups) returns http:NoContent|http:Unauthorized|http:Forbidden|http:NotFound|http:InternalServerError {
        if x\-user\-id is () {
            return unauthorized("missing or invalid token");
        }
        if !isStoreAdmin(x\-user\-groups) {
            return forbidden("caller is not a Store Admin");
        }
        boolean|error deleted = deleteProductRow(productId);
        if deleted is error {
            return <http:InternalServerError>{body: errorPayload(500, "failed to delete product")};
        }
        if !deleted {
            return notFound("product not found");
        }
        return http:NO_CONTENT;
    }
}
