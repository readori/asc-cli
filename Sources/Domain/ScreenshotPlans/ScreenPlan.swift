import Foundation

public struct ScreenPlan: Sendable, Equatable, Identifiable, Codable {
    public var id: String { appId }
    public let appId: String
    public let appName: String
    public let tagline: String
    public let tone: ScreenTone
    public let colors: ScreenColors
    public let screens: [ScreenConfig]

    public init(
        appId: String,
        appName: String,
        tagline: String,
        tone: ScreenTone,
        colors: ScreenColors,
        screens: [ScreenConfig]
    ) {
        self.appId = appId
        self.appName = appName
        self.tagline = tagline
        self.tone = tone
        self.colors = colors
        self.screens = screens
    }
}

extension ScreenPlan: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "generate": "asc app-shots generate --plan app-shots-plan.json --gemini-api-key $GEMINI_API_KEY"
        ]
    }
}
