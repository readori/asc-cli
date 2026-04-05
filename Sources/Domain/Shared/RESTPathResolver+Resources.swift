/// Resource ID → REST segment mappings (used for get/update/delete actions).
/// Shared across all domains — maps `--{param}-id` to the REST path segment.
extension RESTPathResolver {
    static let _resourceMappings: Void = {
        registerResource(param: "version-id", segment: "versions")
        registerResource(param: "app-id", segment: "apps")
        registerResource(param: "build-id", segment: "builds")
        registerResource(param: "localization-id", segment: "version-localizations")
        registerResource(param: "set-id", segment: "screenshot-sets")
        registerResource(param: "review-id", segment: "reviews")
        registerResource(param: "iap-id", segment: "iap")
        registerResource(param: "group-id", segment: "subscription-groups")
        registerResource(param: "subscription-id", segment: "subscriptions")
        registerResource(param: "app-info-id", segment: "app-infos")
        registerResource(param: "certificate-id", segment: "certificates")
        registerResource(param: "device-id", segment: "devices")
        registerResource(param: "profile-id", segment: "profiles")
        registerResource(param: "bundle-id-id", segment: "bundle-ids")
        registerResource(param: "product-id", segment: "xcode-cloud")
        registerResource(param: "workflow-id", segment: "xcode-cloud-workflows")
        registerResource(param: "simulator-id", segment: "simulators")
        registerResource(param: "plugin-id", segment: "plugins")
    }()
}
