// MARK: - Structured Affordance (single source of truth)

/// A structured affordance that can render to both CLI commands and REST links.
///
/// Models define affordances once using this type. The rendering to CLI
/// (`cliCommand`) or REST (`restLink`) is derived automatically.
public struct Affordance: Sendable, Equatable {
    public let key: String
    public let command: String
    public let action: String
    public let params: [String: String]

    public init(key: String, command: String, action: String, params: [String: String] = [:]) {
        self.key = key
        self.command = command
        self.action = action
        self.params = params
    }

    /// Renders as a CLI command: `asc {command} {action} --{k} {v} ...`
    public var cliCommand: String {
        var parts = ["asc", command, action]
        for (k, v) in params.sorted(by: { $0.key < $1.key }) {
            parts.append("--\(k)")
            parts.append(v)
        }
        return parts.joined(separator: " ")
    }

    /// Renders as a REST link with href and HTTP method.
    public var restLink: APILink {
        let method = Self.httpMethod(for: action)
        let path = RESTPathResolver.resolve(command: command, action: action, params: params)
        return APILink(href: path, method: method)
    }

    private static func httpMethod(for action: String) -> String {
        switch action {
        case "list", "get": return "GET"
        case "create": return "POST"
        case "update": return "PATCH"
        case "delete": return "DELETE"
        default: return "POST"
        }
    }
}

// MARK: - APILink

/// A HATEOAS link with an href and HTTP method.
public struct APILink: Sendable, Equatable, Codable {
    public let href: String
    public let method: String

    public init(href: String, method: String) {
        self.href = href
        self.method = method
    }
}

// MARK: - AffordanceMode

/// Controls whether affordances render as CLI commands or REST links.
public enum AffordanceMode: Sendable, Equatable {
    case cli
    case rest
}

// MARK: - REST Path Resolver

/// Resolves CLI command + params into a REST API path.
///
/// Uses a route table mapping CLI commands to their parent parameter
/// and REST segment. The parent parameter determines nesting:
/// `--app-id 123` + `versions` → `/api/v1/apps/123/versions`
public enum RESTPathResolver {

    /// (parentParam, parentSegment, resourceSegment)
    /// parentParam: the CLI flag that identifies the parent resource
    /// parentSegment: the REST path segment for the parent type
    /// resourceSegment: the REST path segment for this resource
    private static let routeTable: [String: (parentParam: String, parentSegment: String, segment: String)] = [
        // App children
        "versions": (parentParam: "app-id", parentSegment: "apps", segment: "versions"),
        "builds": (parentParam: "app-id", parentSegment: "apps", segment: "builds"),
        "reviews": (parentParam: "app-id", parentSegment: "apps", segment: "reviews"),
        "app-infos": (parentParam: "app-id", parentSegment: "apps", segment: "app-infos"),
        "testflight": (parentParam: "app-id", parentSegment: "apps", segment: "testflight"),

        // Version children
        "version-localizations": (parentParam: "version-id", parentSegment: "versions", segment: "localizations"),

        // Localization children
        "screenshot-sets": (parentParam: "localization-id", parentSegment: "version-localizations", segment: "screenshot-sets"),
        "screenshots": (parentParam: "set-id", parentSegment: "screenshot-sets", segment: "screenshots"),
    ]

    /// Maps CLI `--{param}-id` to the REST segment for the resource itself (used for get/update/delete).
    private static let resourceTable: [String: String] = [
        "version-id": "versions",
        "app-id": "apps",
        "build-id": "builds",
        "localization-id": "version-localizations",
        "set-id": "screenshot-sets",
        "review-id": "reviews",
    ]

    static func resolve(command: String, action: String, params: [String: String]) -> String {
        let base = "/api/v1"

        // Actions on an existing resource by its own ID (get, update, delete, submit, etc.)
        if action != "list" && action != "create" {
            // Find the resource's own ID param (e.g. "version-id" for "versions")
            let idParam = "\(singularize(command))-id"
            if let idValue = params[idParam] {
                let segment = resourceTable[idParam] ?? command
                if action == "get" || action == "update" || action == "delete" {
                    return "\(base)/\(segment)/\(idValue)"
                }
                // Custom actions (submit, etc.) → POST /resource/id/action
                return "\(base)/\(segment)/\(idValue)/\(action)"
            }
        }

        // List/create under parent
        if let route = routeTable[command] {
            if let parentId = params[route.parentParam] {
                return "\(base)/\(route.parentSegment)/\(parentId)/\(route.segment)"
            }
        }

        // Top-level resource (e.g. apps list)
        return "\(base)/\(command)"
    }

    /// Naive singularization: "versions" → "version", "builds" → "build"
    private static func singularize(_ command: String) -> String {
        if command.hasSuffix("s") {
            return String(command.dropLast())
        }
        return command
    }
}