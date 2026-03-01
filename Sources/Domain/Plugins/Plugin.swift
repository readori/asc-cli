/// A user-installed plugin that extends ASC with custom event handlers.
///
/// Plugins live in `~/.asc/plugins/<name>/` and contain a `manifest.json`
/// plus an executable named `run`. ASC invokes `run` with a JSON event
/// payload on stdin and reads a `PluginResult` JSON from stdout.
public struct Plugin: Sendable, Equatable, Identifiable {
    public let id: String           // = name, unique plugin identifier
    public let name: String
    public let version: String
    public let description: String
    public let author: String?
    public let executablePath: String
    public let subscribedEvents: [PluginEvent]
    public let isEnabled: Bool

    public init(
        id: String,
        name: String,
        version: String,
        description: String,
        author: String? = nil,
        executablePath: String,
        subscribedEvents: [PluginEvent],
        isEnabled: Bool
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.executablePath = executablePath
        self.subscribedEvents = subscribedEvents
        self.isEnabled = isEnabled
    }
}

extension Plugin: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, version, description, author, executablePath, subscribedEvents, isEnabled
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        version = try c.decode(String.self, forKey: .version)
        description = try c.decode(String.self, forKey: .description)
        author = try c.decodeIfPresent(String.self, forKey: .author)
        executablePath = try c.decode(String.self, forKey: .executablePath)
        subscribedEvents = try c.decode([PluginEvent].self, forKey: .subscribedEvents)
        isEnabled = try c.decode(Bool.self, forKey: .isEnabled)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(version, forKey: .version)
        try c.encode(description, forKey: .description)
        try c.encodeIfPresent(author, forKey: .author)
        try c.encode(executablePath, forKey: .executablePath)
        try c.encode(subscribedEvents, forKey: .subscribedEvents)
        try c.encode(isEnabled, forKey: .isEnabled)
    }
}

extension Plugin: AffordanceProviding {
    public var affordances: [String: String] {
        var cmds: [String: String] = [
            "listPlugins": "asc plugins list",
            "uninstall": "asc plugins uninstall --name \(name)",
        ]
        if isEnabled {
            cmds["disable"] = "asc plugins disable --name \(name)"
        } else {
            cmds["enable"] = "asc plugins enable --name \(name)"
        }
        for event in PluginEvent.allCases {
            let key = "run.\(event.rawValue)"
            cmds[key] = "asc plugins run --name \(name) --event \(event.rawValue)"
        }
        return cmds
    }
}
