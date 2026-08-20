import ballerina/os;

// ceramics-db (platform-resource, postgres-cnpg)
configurable string ceramicsDbHost = os:getEnv("CERAMICS_DB_HOST");
configurable string ceramicsDbPort = os:getEnv("CERAMICS_DB_PORT");
configurable string ceramicsDbUser = os:getEnv("CERAMICS_DB_USER");
configurable string ceramicsDbPassword = os:getEnv("CERAMICS_DB_PASSWORD");
configurable string ceramicsDbName = os:getEnv("CERAMICS_DB_DBNAME");

// user-auth (platform-resource, thunder-app) - the gateway validates the
// bearer token and injects X-User-Id / X-User-Groups / X-User-Name, so this
// service never parses or validates a JWT itself. Kept here only because it
// is a declared dependency the platform provisions.
configurable string userAuthClientId = os:getEnv("USER_AUTH_CLIENT_ID");
configurable string userAuthIssuer = os:getEnv("USER_AUTH_ISSUER");
configurable string userAuthJwksUrl = os:getEnv("USER_AUTH_JWKS_URL");
configurable string userAuthScopes = os:getEnv("USER_AUTH_SCOPES");

// payment-provider (external, Stripe)
configurable string stripeApiKey = os:getEnv("STRIPE_API_KEY");
configurable string stripeWebhookSecret = os:getEnv("STRIPE_WEBHOOK_SECRET");

// Not platform-wired settings below - own configuration this service needs,
// each with a sensible default so the service starts without them set.
configurable string flatShippingFeeRaw = os:getEnv("FLAT_SHIPPING_FEE");
configurable string checkoutSuccessUrlRaw = os:getEnv("CHECKOUT_SUCCESS_URL");
configurable string checkoutCancelUrlRaw = os:getEnv("CHECKOUT_CANCEL_URL");

// Flat shipping fee (USD) applied identically to every order regardless of
// contents. The PRD (story 7) fixes only that the fee is flat, not an
// amount, so a reasonable constant is the default; FLAT_SHIPPING_FEE
// overrides it.
function resolveFlatShippingFee() returns decimal {
    if flatShippingFeeRaw == "" {
        return 5.00d;
    }
    decimal|error parsed = decimal:fromString(flatShippingFeeRaw);
    if parsed is decimal {
        return parsed;
    }
    return 5.00d;
}

final decimal flatShippingFee = resolveFlatShippingFee();

// Stripe's hosted Checkout Session API requires absolute redirect URLs. No
// dependency wiring hands this service the webapp's public origin, so these
// are this service's own env vars, defaulting to a placeholder origin that
// keeps checkout-session creation working (Stripe only validates URL shape)
// until the real webapp URL is configured for the deployment.
function resolveCheckoutUrl(string configured, string defaultPath) returns string {
    if configured != "" {
        return configured;
    }
    return "https://example.com" + defaultPath;
}

final string checkoutSuccessUrl = resolveCheckoutUrl(checkoutSuccessUrlRaw, "/checkout/success?session_id={CHECKOUT_SESSION_ID}");
final string checkoutCancelUrl = resolveCheckoutUrl(checkoutCancelUrlRaw, "/checkout/cancel");
