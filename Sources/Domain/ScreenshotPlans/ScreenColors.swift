public struct ScreenColors: Sendable, Equatable, Codable {
    public let primary: String
    public let accent: String
    public let text: String
    public let subtext: String

    public init(primary: String, accent: String, text: String, subtext: String) {
        self.primary = primary
        self.accent = accent
        self.text = text
        self.subtext = subtext
    }
}
