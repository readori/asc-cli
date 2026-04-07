import Domain
import Foundation

/// Aggregates gallery templates from all registered providers.
///
/// Plugins register providers to supply gallery templates.
/// Use `AggregateGalleryTemplateRepository.shared` as the global registry.
public final actor AggregateGalleryTemplateRepository: GalleryTemplateRepository {
    public static let shared = AggregateGalleryTemplateRepository()

    private var providers: [any GalleryTemplateProvider] = []

    public init() {}

    public func register(provider: any GalleryTemplateProvider) {
        providers.append(provider)
    }

    public func listGalleryTemplates() async throws -> [GalleryTemplate] {
        var all: [GalleryTemplate] = []
        for provider in providers {
            let templates = try await provider.galleryTemplates()
            all.append(contentsOf: templates)
        }
        return all
    }

    public func getGalleryTemplate(id: String) async throws -> GalleryTemplate? {
        let all = try await listGalleryTemplates()
        return all.first { $0.id == id }
    }
}
