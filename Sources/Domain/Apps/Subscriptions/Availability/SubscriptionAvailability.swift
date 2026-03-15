public struct SubscriptionAvailability: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent subscription identifier — injected by Infrastructure since ASC API omits it from response
    public let subscriptionId: String
    public let isAvailableInNewTerritories: Bool
    public let territories: [Territory]

    public init(
        id: String,
        subscriptionId: String,
        isAvailableInNewTerritories: Bool,
        territories: [Territory]
    ) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.isAvailableInNewTerritories = isAvailableInNewTerritories
        self.territories = territories
    }
}

extension SubscriptionAvailability: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "createAvailability": "asc subscription-availability create --subscription-id \(subscriptionId) --available-in-new-territories --territory USA --territory CHN",
            "getAvailability": "asc subscription-availability get --subscription-id \(subscriptionId)",
            "listTerritories": "asc territories list",
        ]
    }
}
