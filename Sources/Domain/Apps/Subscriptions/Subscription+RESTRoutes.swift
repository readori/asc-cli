/// REST route registrations for Subscription hierarchy.
extension RESTPathResolver {
    static let _subscriptionRoutes: Void = {
        registerRoute(command: "subscriptions", parentParam: "group-id", parentSegment: "subscription-groups", segment: "subscriptions")
        registerRoute(command: "subscription-localizations", parentParam: "subscription-id", parentSegment: "subscriptions", segment: "localizations")
        registerRoute(command: "subscription-offer-codes", parentParam: "subscription-id", parentSegment: "subscriptions", segment: "offer-codes")
        registerRoute(command: "subscription-offers", parentParam: "subscription-id", parentSegment: "subscriptions", segment: "introductory-offers")
        registerRoute(command: "subscription-availability", parentParam: "subscription-id", parentSegment: "subscriptions", segment: "availability")
    }()
}
