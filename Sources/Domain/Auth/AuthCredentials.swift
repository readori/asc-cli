public struct AuthCredentials: Sendable, Equatable {
    public let keyID: String
    public let issuerID: String
    public let privateKeyPEM: String
    public let vendorNumber: String?

    public init(keyID: String, issuerID: String, privateKeyPEM: String, vendorNumber: String? = nil) {
        self.keyID = keyID
        self.issuerID = issuerID
        self.privateKeyPEM = privateKeyPEM
        self.vendorNumber = vendorNumber
    }

    public func validate() throws {
        guard !keyID.isEmpty else {
            throw AuthError.missingKeyID
        }
        guard !issuerID.isEmpty else {
            throw AuthError.missingIssuerID
        }
        guard !privateKeyPEM.isEmpty else {
            throw AuthError.missingPrivateKey
        }
    }
}

extension AuthCredentials: Codable {
    private enum CodingKeys: String, CodingKey {
        case keyID, issuerID, privateKeyPEM, vendorNumber
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyID = try container.decode(String.self, forKey: .keyID)
        issuerID = try container.decode(String.self, forKey: .issuerID)
        privateKeyPEM = try container.decode(String.self, forKey: .privateKeyPEM)
        vendorNumber = try container.decodeIfPresent(String.self, forKey: .vendorNumber)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyID, forKey: .keyID)
        try container.encode(issuerID, forKey: .issuerID)
        try container.encode(privateKeyPEM, forKey: .privateKeyPEM)
        try container.encodeIfPresent(vendorNumber, forKey: .vendorNumber)
    }
}
