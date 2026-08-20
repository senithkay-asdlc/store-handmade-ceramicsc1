// The gateway terminates auth and injects the caller's verified identity as
// headers - this service trusts them and never validates a JWT itself
// (thunder-authentication / api-management). X-User-Id is the caller's
// opaque, stable subject id: rows are owned by it directly, with no
// directory lookup. X-User-Groups carries the caller's role groups; a
// "store-admin" (or any group whose name contains "admin") group makes the
// caller a Store Admin per specs/design/security.md.

function isStoreAdmin(string? groupsHeader) returns boolean {
    if groupsHeader is () {
        return false;
    }
    string header = groupsHeader;
    if header == "" {
        return false;
    }
    foreach string group in parseGroups(header) {
        if group.toLowerAscii().includes("admin") {
            return true;
        }
    }
    return false;
}

function parseGroups(string header) returns string[] {
    json|error parsed = header.fromJsonString();
    if parsed is json[] {
        string[] groups = [];
        foreach json item in parsed {
            if item is string {
                groups.push(item);
            }
        }
        return groups;
    }
    // Fallback: a plain comma-separated list of group names.
    return re `\s*,\s*`.split(header);
}
