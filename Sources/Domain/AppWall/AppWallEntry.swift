import Foundation

/// A developer entry in the app wall (`homepage/apps.json`).
public struct AppWallEntry: Sendable, Equatable, Codable, Identifiable {
    public var id: String { github }
    public let developer: String
    public let developerId: String
    public let github: String
    public let x: String?

    public init(developer: String, developerId: String, github: String, x: String? = nil) {
        self.developer = developer
        self.developerId = developerId
        self.github = github
        self.x = x
    }

    // Custom Codable: omit nil x from JSON output
    enum CodingKeys: String, CodingKey {
        case developer, developerId, github, x
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(developer, forKey: .developer)
        try container.encode(developerId, forKey: .developerId)
        try container.encode(github, forKey: .github)
        try container.encodeIfPresent(x, forKey: .x)
    }
}
