import Foundation
import Mockable

/// A provider that supplies gallery templates.
///
/// Plugins register providers to contribute their gallery templates.
@Mockable
public protocol GalleryTemplateProvider: Sendable {
    var providerId: String { get }
    func galleryTemplates() async throws -> [GalleryTemplate]
}

/// Repository for querying gallery templates.
@Mockable
public protocol GalleryTemplateRepository: Sendable {
    func listGalleryTemplates() async throws -> [GalleryTemplate]
    func getGalleryTemplate(id: String) async throws -> GalleryTemplate?
}
