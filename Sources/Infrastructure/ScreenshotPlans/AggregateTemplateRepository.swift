import Domain
import Foundation

/// Aggregates templates from all registered `TemplateProvider`s.
///
/// The platform ships with no built-in templates. Plugins register
/// providers to supply their own templates.
public final class AggregateTemplateRepository: TemplateRepository, @unchecked Sendable {
    private var providers: [any TemplateProvider] = []
    private let lock = NSLock()

    public init() {}

    public func register(provider: any TemplateProvider) async {
        lock.lock()
        providers.append(provider)
        lock.unlock()
    }

    public func listTemplates(size: ScreenSize?) async throws -> [ScreenshotTemplate] {
        let currentProviders: [any TemplateProvider]
        lock.lock()
        currentProviders = providers
        lock.unlock()

        var all: [ScreenshotTemplate] = []
        for provider in currentProviders {
            let templates = try await provider.templates()
            all.append(contentsOf: templates)
        }

        if let size {
            return all.filter { $0.supportedSizes.contains(size) }
        }
        return all
    }

    public func getTemplate(id: String) async throws -> ScreenshotTemplate? {
        let all = try await listTemplates(size: nil)
        return all.first { $0.id == id }
    }
}
