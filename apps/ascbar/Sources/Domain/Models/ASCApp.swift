/// An App Store Connect app — mirrors the JSON output of `asc apps list`.
public struct ASCApp: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public let name: String
    public let bundleId: String
    public let sku: String?
    public let primaryLocale: String?

    public init(
        id: String,
        name: String,
        bundleId: String,
        sku: String? = nil,
        primaryLocale: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.sku = sku
        self.primaryLocale = primaryLocale
    }

    public var displayName: String {
        name.isEmpty ? bundleId : name
    }

    // Ignore `affordances` field emitted by asc CLI
    private enum CodingKeys: String, CodingKey {
        case id, name, bundleId, sku, primaryLocale
    }
}
