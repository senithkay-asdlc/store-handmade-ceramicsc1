import ballerina/http;

// Shared helpers for building the Error payload the OpenAPI spec attaches to
// every 4xx/5xx response.

function errorPayload(int code, string message, string description = "") returns ErrorPayload {
    if description == "" {
        return {code, message};
    }
    return {code, message, description};
}

function badRequest(string message) returns http:BadRequest {
    return <http:BadRequest>{body: errorPayload(400, message)};
}

function unauthorized(string message) returns http:Unauthorized {
    return <http:Unauthorized>{body: errorPayload(401, message)};
}

function forbidden(string message) returns http:Forbidden {
    return <http:Forbidden>{body: errorPayload(403, message)};
}

function notFound(string message) returns http:NotFound {
    return <http:NotFound>{body: errorPayload(404, message)};
}
