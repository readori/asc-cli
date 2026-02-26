/// Overall status derived from an app's active versions.
public enum AppStatus: Sendable, Equatable {
    /// Has a live version on the App Store
    case live
    /// Has a version ready to be edited or submitted
    case editable
    /// Version is in Apple's review pipeline
    case pending
    /// Version removed from sale
    case removed
    /// Processing or unknown state
    case processing

    public var displayName: String {
        switch self {
        case .live: return "Live"
        case .editable: return "Editable"
        case .pending: return "In Review"
        case .removed: return "Removed"
        case .processing: return "Processing"
        }
    }

    public var symbolName: String {
        switch self {
        case .live: return "checkmark.circle.fill"
        case .editable: return "pencil.circle.fill"
        case .pending: return "clock.fill"
        case .removed: return "xmark.circle.fill"
        case .processing: return "arrow.triangle.2.circlepath"
        }
    }

    /// Maps to a menu bar icon name
    public var menuBarSymbol: String {
        switch self {
        case .live: return "app.badge.checkmark.fill"
        case .editable: return "app.fill"
        case .pending: return "clock.badge.fill"
        case .removed: return "app.badge.fill"
        case .processing: return "app.fill"
        }
    }
}
