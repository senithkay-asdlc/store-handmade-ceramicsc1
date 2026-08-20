import ballerina/crypto;
import ballerina/http;
import ballerina/time;
import ballerina/url;

// Ballerina has no official Stripe SDK, so this is a minimal HTTP client
// against Stripe's REST API using ballerina/http - hosted Checkout Session
// creation (form-encoded POST) plus webhook signature verification
// implemented directly from Stripe's documented HMAC-SHA256 scheme.

final http:Client stripeClient = check new ("https://api.stripe.com",
    auth = {token: stripeApiKey}
);

const int STRIPE_WEBHOOK_TOLERANCE_SECONDS = 300;

public type CheckoutLineItem record {|
    string name;
    int unitAmountCents;
    int quantity;
|};

public type CheckoutSession record {|
    string sessionId;
    string url;
|};

function toCents(decimal amount) returns int {
    decimal cents = amount * 100d;
    return <int>cents;
}

function buildCheckoutSessionBody(string orderId, CheckoutLineItem[] items, int shippingFeeCents, string? guestEmail) returns string|error {
    string[] parts = [
        "mode=payment",
        "payment_method_types[]=card",
        "success_url=" + check url:encode(checkoutSuccessUrl, "UTF-8"),
        "cancel_url=" + check url:encode(checkoutCancelUrl, "UTF-8"),
        "metadata[order_id]=" + check url:encode(orderId, "UTF-8")
    ];
    if guestEmail is string && guestEmail != "" {
        parts.push("customer_email=" + check url:encode(guestEmail, "UTF-8"));
    }
    int idx = 0;
    foreach CheckoutLineItem item in items {
        string prefix = "line_items[" + idx.toString() + "]";
        parts.push(prefix + "[price_data][currency]=usd");
        parts.push(prefix + "[price_data][unit_amount]=" + item.unitAmountCents.toString());
        parts.push(prefix + "[price_data][product_data][name]=" + check url:encode(item.name, "UTF-8"));
        parts.push(prefix + "[quantity]=" + item.quantity.toString());
        idx += 1;
    }
    string shippingPrefix = "line_items[" + idx.toString() + "]";
    parts.push(shippingPrefix + "[price_data][currency]=usd");
    parts.push(shippingPrefix + "[price_data][unit_amount]=" + shippingFeeCents.toString());
    parts.push(shippingPrefix + "[price_data][product_data][name]=" + check url:encode("Shipping", "UTF-8"));
    parts.push(shippingPrefix + "[quantity]=1");
    return string:'join("&", ...parts);
}

function createCheckoutSession(string orderId, CheckoutLineItem[] items, decimal shippingFee, string? guestEmail) returns CheckoutSession|error {
    string body = check buildCheckoutSessionBody(orderId, items, toCents(shippingFee), guestEmail);
    http:Response response = check stripeClient->post("/v1/checkout/sessions", body, mediaType = "application/x-www-form-urlencoded");
    json payload = check response.getJsonPayload();
    if response.statusCode != 200 {
        return error("stripe checkout session creation failed: " + payload.toJsonString());
    }
    map<json> sessionObj = check payload.ensureType();
    string sessionId = check sessionObj["id"].ensureType();
    string checkoutUrl = check sessionObj["url"].ensureType();
    return {sessionId, url: checkoutUrl};
}

// Verifies the Stripe-Signature header per Stripe's documented scheme:
// HMAC-SHA256 over "{timestamp}.{payload}" using the webhook signing secret,
// compared against every v1= signature in the header, rejecting a timestamp
// that is too old (replay protection).
function verifyStripeSignature(string payload, string? signatureHeader) returns boolean {
    if signatureHeader is () || signatureHeader == "" {
        return false;
    }
    string header = signatureHeader;
    string? timestamp = ();
    string[] v1Signatures = [];
    foreach string part in re `,`.split(header) {
        string[] kv = re `=`.split(part);
        if kv.length() < 2 {
            continue;
        }
        string key = kv[0];
        string value = kv[1];
        if key == "t" {
            timestamp = value;
        } else if key == "v1" {
            v1Signatures.push(value);
        }
    }
    if timestamp is () || v1Signatures.length() == 0 {
        return false;
    }
    string ts = timestamp;
    int|error parsedTs = int:fromString(ts);
    if parsedTs is error {
        return false;
    }
    int nowSeconds = time:utcNow()[0];
    int age = nowSeconds - parsedTs;
    if age > STRIPE_WEBHOOK_TOLERANCE_SECONDS || age < -STRIPE_WEBHOOK_TOLERANCE_SECONDS {
        return false;
    }
    string signedPayload = ts + "." + payload;
    byte[]|crypto:Error computed = crypto:hmacSha256(signedPayload.toBytes(), stripeWebhookSecret.toBytes());
    if computed is crypto:Error {
        return false;
    }
    string computedHex = computed.toBase16().toLowerAscii();
    foreach string candidate in v1Signatures {
        if candidate.toLowerAscii() == computedHex {
            return true;
        }
    }
    return false;
}
