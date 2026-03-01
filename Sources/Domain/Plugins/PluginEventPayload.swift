import Foundation

/// Data delivered to a plugin when an event fires.
public struct PluginEventPayload: Sendable, Equatable, Codable {
    public let event: PluginEvent
    public let appId: String?
    public let versionId: String?
    public let buildId: String?
    public let timestamp: Date
    public let metadata: [String: String]

    public init(
        event: PluginEvent,
        appId: String? = nil,
        versionId: String? = nil,
        buildId: String? = nil,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.event = event
        self.appId = appId
        self.versionId = versionId
        self.buildId = buildId
        self.timestamp = timestamp
        self.metadata = metadata
    }
}
