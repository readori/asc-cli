/// A resource that advertises its available CLI actions.
///
/// CLI equivalent of REST HATEOAS. Conforming types embed ready-to-run
/// commands in responses so agents can navigate without memorising the
/// command tree.
///
/// Models should implement `structuredAffordances` as the single source of
/// truth. The `affordances` (CLI) and `apiLinks` (REST) properties are
/// derived automatically from it. Models that haven't migrated yet can
/// still override `affordances` directly — both paths coexist.
public protocol AffordanceProviding {
    /// Structured affordances — single source of truth for both CLI and REST.
    var structuredAffordances: [Affordance] { get }

    /// CLI affordances: `[actionName: "asc command action --flag value"]`.
    /// Default implementation derives from `structuredAffordances`.
    var affordances: [String: String] { get }

    /// REST HATEOAS links: `[actionName: APILink(href, method)]`.
    /// Derived from `structuredAffordances`.
    var apiLinks: [String: APILink] { get }

    /// Properties passed to `AffordanceRegistry` so plugins can make decisions
    /// (e.g. only show "stream" when `isBooted` is true).
    var registryProperties: [String: String] { get }
}

extension AffordanceProviding {
    /// Default: no structured affordances. Models that still override
    /// `affordances` directly will use their own implementation.
    public var structuredAffordances: [Affordance] { [] }

    /// Derives CLI affordances from `structuredAffordances`.
    /// Models that override `affordances` directly bypass this.
    public var affordances: [String: String] {
        Dictionary(uniqueKeysWithValues: structuredAffordances.map { ($0.key, $0.cliCommand) })
    }

    /// Derives REST links from `structuredAffordances`.
    public var apiLinks: [String: APILink] {
        Dictionary(uniqueKeysWithValues: structuredAffordances.map { ($0.key, $0.restLink) })
    }

    public var registryProperties: [String: String] { [:] }
}