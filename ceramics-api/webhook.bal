import ballerina/http;
import ballerina/log;

// Stripe payment-confirmation webhook. Not part of specs/design/components/
// ceramics-api/openapi.yaml (that document is the shopper/admin-facing
// contract) but required by the issue to transition an order to `paid` only
// on a genuinely successful, signature-verified payment.

function extractOrderId(map<json> sessionObj) returns string?|error {
    json metadataJson = sessionObj["metadata"];
    if metadataJson is map<json> {
        json orderIdJson = metadataJson["order_id"];
        if orderIdJson is string {
            return orderIdJson;
        }
    }
    json idJson = sessionObj["id"];
    if idJson is string {
        return findOrderIdBySessionId(idJson);
    }
    return ();
}

function handleCheckoutSessionCompleted(map<json> sessionObj) {
    json paymentStatusJson = sessionObj["payment_status"];
    if !(paymentStatusJson is string) || paymentStatusJson != "paid" {
        // Not a confirmed payment (e.g. still pending on an async method) -
        // leave the order as-is; a later event will confirm or fail it.
        return;
    }
    string?|error orderId = extractOrderId(sessionObj);
    if orderId is error {
        log:printError("failed to resolve order for stripe session", 'error = orderId);
        return;
    }
    if orderId is () {
        log:printWarn("stripe checkout.session.completed with no matching order");
        return;
    }
    string resolvedOrderId = orderId;
    error? err = markOrderPaid(resolvedOrderId);
    if err is error {
        log:printError("failed to mark order paid", 'error = err, orderId = resolvedOrderId);
    }
}

service /webhooks on httpListener {

    resource function post stripe(http:Request request) returns http:Ok|http:BadRequest {
        string|http:ClientError payloadResult = request.getTextPayload();
        if payloadResult is http:ClientError {
            return badRequest("invalid payload");
        }
        string payload = payloadResult;

        string|http:HeaderNotFoundError signatureResult = request.getHeader("Stripe-Signature");
        string? signature = signatureResult is string ? signatureResult : ();
        if !verifyStripeSignature(payload, signature) {
            return badRequest("invalid signature");
        }

        json|error parsed = payload.fromJsonString();
        if parsed is error {
            return badRequest("invalid payload");
        }
        map<json>|error eventObj = parsed.ensureType();
        if eventObj is error {
            return badRequest("invalid payload");
        }

        json eventTypeJson = eventObj["type"];
        string eventType = eventTypeJson is string ? eventTypeJson : "";

        if eventType == "checkout.session.completed" {
            json dataJson = eventObj["data"];
            if dataJson is map<json> {
                json objectJson = dataJson["object"];
                if objectJson is map<json> {
                    handleCheckoutSessionCompleted(objectJson);
                }
            }
        } else if eventType == "checkout.session.async_payment_failed" || eventType == "payment_intent.payment_failed" {
            // A failed/declined payment must never mark an order paid: the
            // order was persisted as `pending` at checkout and simply stays
            // there, so no state change is needed - just record it happened.
            log:printInfo("stripe payment failed", eventType = eventType);
        }

        return http:OK;
    }
}
