/// An App Store version — mirrors the JSON output of `asc versions list`.
/// State and platform values match the raw strings from the asc CLI (e.g. "READY_FOR_SALE", "IOS").
public struct ASCVersion: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public let appId: String
    public let versionString: String
    public let platform: String
    public let state: String
    public let buildId: String?

    public init(
        id: String,
        appId: String,
        versionString: String,
        platform: String,
        state: String,
        buildId: String? = nil
    ) {
        self.id = id
        self.appId = appId
        self.versionString = versionString
        self.platform = platform
        self.state = state
        self.buildId = buildId
    }

    // Ignore `affordances` and `createdDate` from asc CLI output
    private enum CodingKeys: String, CodingKey {
        case id, appId, versionString, platform, state, buildId
    }

    public var appStatus: AppStatus {
        switch state {
        case "READY_FOR_SALE":
            return .live
        case "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED":
            return .editable
        case "WAITING_FOR_REVIEW", "IN_REVIEW", "PENDING_DEVELOPER_RELEASE",
             "PENDING_APPLE_RELEASE", "PROCESSING_FOR_APP_STORE", "WAITING_FOR_EXPORT_COMPLIANCE":
            return .pending
        case "REMOVED_FROM_SALE", "DEVELOPER_REMOVED_FROM_SALE":
            return .removed
        default:
            return .processing
        }
    }

    public var stateDisplayName: String {
        switch state {
        case "PREPARE_FOR_SUBMISSION": return "Prepare for Submission"
        case "WAITING_FOR_REVIEW": return "Waiting for Review"
        case "IN_REVIEW": return "In Review"
        case "PENDING_DEVELOPER_RELEASE": return "Pending Developer Release"
        case "PENDING_APPLE_RELEASE": return "Pending Apple Release"
        case "PROCESSING_FOR_APP_STORE": return "Processing"
        case "READY_FOR_SALE": return "Ready for Sale"
        case "DEVELOPER_REJECTED": return "Developer Rejected"
        case "REJECTED": return "Rejected"
        case "METADATA_REJECTED": return "Metadata Rejected"
        case "REMOVED_FROM_SALE": return "Removed from Sale"
        case "DEVELOPER_REMOVED_FROM_SALE": return "Dev Removed from Sale"
        case "INVALID_BINARY": return "Invalid Binary"
        case "WAITING_FOR_EXPORT_COMPLIANCE": return "Waiting for Export Compliance"
        default: return state
        }
    }

    public var platformDisplayName: String {
        switch platform {
        case "IOS": return "iOS"
        case "MAC_OS": return "macOS"
        case "TV_OS": return "tvOS"
        case "WATCH_OS": return "watchOS"
        case "VISION_OS": return "visionOS"
        default: return platform
        }
    }

    public var isEditable: Bool { appStatus == .editable }
    public var isLive: Bool { appStatus == .live }
    public var isPending: Bool { appStatus == .pending }
}
