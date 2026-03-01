/// Response returned by a plugin executable via stdout.
public struct PluginResult: Sendable, Equatable {
    public let success: Bool
    public let message: String?
    public let error: String?

    public init(success: Bool, message: String? = nil, error: String? = nil) {
        self.success = success
        self.message = message
        self.error = error
    }
}

extension PluginResult: Codable {
    enum CodingKeys: String, CodingKey {
        case success, message, error
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try c.decode(Bool.self, forKey: .success)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        error = try c.decodeIfPresent(String.self, forKey: .error)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(success, forKey: .success)
        try c.encodeIfPresent(message, forKey: .message)
        try c.encodeIfPresent(error, forKey: .error)
    }
}
