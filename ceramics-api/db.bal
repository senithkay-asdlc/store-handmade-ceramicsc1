import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

function resolveDbPort() returns int {
    if ceramicsDbPort == "" {
        return 5432;
    }
    int|error parsed = int:fromString(ceramicsDbPort);
    if parsed is int {
        return parsed;
    }
    return 5432;
}

final postgresql:Client dbClient = check new (
    host = ceramicsDbHost,
    port = resolveDbPort(),
    username = ceramicsDbUser,
    password = ceramicsDbPassword,
    database = ceramicsDbName
);

function initSchema() returns error? {
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS products (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            price NUMERIC(12,2) NOT NULL,
            photo_url TEXT,
            stock_quantity INTEGER NOT NULL DEFAULT 0,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS carts (
            id TEXT PRIMARY KEY,
            customer_id TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS cart_items (
            id TEXT PRIMARY KEY,
            cart_id TEXT NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
            product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
            quantity INTEGER NOT NULL
        )
    `);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON cart_items(cart_id)`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS orders (
            id TEXT PRIMARY KEY,
            customer_id TEXT,
            guest_email TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            shipping_fee NUMERIC(12,2) NOT NULL,
            total NUMERIC(12,2) NOT NULL,
            shipping_address TEXT,
            stripe_session_id TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    `);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id)`);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_orders_stripe_session_id ON orders(stripe_session_id)`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS order_items (
            id TEXT PRIMARY KEY,
            order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
            product_id TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price NUMERIC(12,2) NOT NULL
        )
    `);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id)`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS order_status_history (
            id TEXT PRIMARY KEY,
            order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
            status TEXT NOT NULL,
            changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    `);
    _ = check dbClient->execute(`CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON order_status_history(order_id)`);
}

function init() returns error? {
    check initSchema();
}
