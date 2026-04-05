/// REST route registrations for IAP children.
extension RESTPathResolver {
    static let _iapRoutes: Void = {
        registerRoute(command: "iap-localizations", parentParam: "iap-id", parentSegment: "iap", segment: "localizations")
        registerRoute(command: "iap-offer-codes", parentParam: "iap-id", parentSegment: "iap", segment: "offer-codes")
        registerRoute(command: "iap-availability", parentParam: "iap-id", parentSegment: "iap", segment: "availability")
    }()
}
