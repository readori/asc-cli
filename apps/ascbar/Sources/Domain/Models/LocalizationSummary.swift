/// A single version localization entry — mapped from `asc version-localizations list` output.
public struct LocalizationSummary: Sendable, Equatable, Identifiable {
    public let id: String
    /// BCP 47 locale code, e.g. "en-US".
    public let locale: String
    /// True for the first locale returned by the API (the app's primary locale).
    public let isPrimary: Bool

    // Text fields — nil when not yet set for this locale
    public let whatsNew: String?
    public let description: String?
    public let keywords: String?
    public let marketingUrl: String?
    public let supportUrl: String?
    public let promotionalText: String?

    public init(
        id: String,
        locale: String,
        isPrimary: Bool,
        whatsNew: String? = nil,
        description: String? = nil,
        keywords: String? = nil,
        marketingUrl: String? = nil,
        supportUrl: String? = nil,
        promotionalText: String? = nil
    ) {
        self.id = id
        self.locale = locale
        self.isPrimary = isPrimary
        self.whatsNew = whatsNew
        self.description = description
        self.keywords = keywords
        self.marketingUrl = marketingUrl
        self.supportUrl = supportUrl
        self.promotionalText = promotionalText
    }

    /// Number of text fields that have a non-empty value.
    public var setFieldCount: Int {
        [whatsNew, description, keywords, marketingUrl, supportUrl, promotionalText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .count
    }
}
