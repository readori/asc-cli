/// Events that ASC emits during operations, triggering subscribed plugins.
public enum PluginEvent: String, Sendable, Equatable, Codable, CaseIterable {
    case buildUploaded = "build.uploaded"
    case versionSubmitted = "version.submitted"
    case versionApproved = "version.approved"
    case versionRejected = "version.rejected"

    public var displayName: String { rawValue }
}
