public struct AppAvailability: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    /// Parent app identifier — injected by Infrastructure since ASC API omits it from response
    public let appId: String
    public let isAvailableInNewTerritories: Bool
    public let territories: [AppTerritoryAvailability]

    public init(
        id: String,
        appId: String,
        isAvailableInNewTerritories: Bool,
        territories: [AppTerritoryAvailability]
    ) {
        self.id = id
        self.appId = appId
        self.isAvailableInNewTerritories = isAvailableInNewTerritories
        self.territories = territories
    }
}

extension AppAvailability: AffordanceProviding {
    public var affordances: [String: String] {
        [
            "getAvailability": "asc app-availability get --app-id \(appId)",
            "listTerritories": "asc territories list",
        ]
    }
}
