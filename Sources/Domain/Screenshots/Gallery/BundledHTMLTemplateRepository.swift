import Foundation

/// Default template repository that loads HTML templates from the Domain module's bundle resources.
///
/// Templates are `.html` files in `Sources/Domain/Screenshots/Gallery/Resources/`.
/// This is the fallback when no custom template repository is registered.
public struct BundledHTMLTemplateRepository: HTMLTemplateRepository, Sendable {
    public init() {}

    public func template(named name: String) -> String? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "html", subdirectory: "Resources") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
