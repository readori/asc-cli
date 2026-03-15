public struct InAppPurchaseAvailability: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent IAP identifier — injected by Infrastructure since ASC API omits it from response
    public let iapId: String
    public let isAvailableInNewTerritories: Bool
    public let territories: [Territory]

    public init(
        id: String,
        iapId: String,
        isAvailableInNewTerritories: Bool,
        territories: [Territory]
    ) {
        self.id = id
        self.iapId = iapId
        self.isAvailableInNewTerritories = isAvailableInNewTerritories
        self.territories = territories
    }
}

extension InAppPurchaseAvailability: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "createAvailability": "asc iap-availability create --iap-id \(iapId) --available-in-new-territories --territory USA --territory CHN",
            "getAvailability": "asc iap-availability get --iap-id \(iapId)",
            "listTerritories": "asc territories list",
        ]
    }
}
