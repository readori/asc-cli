import Foundation
import Testing
import Mockable
@testable import Domain

@Suite("GalleryTemplateRepository")
struct GalleryTemplateRepositoryTests {

    // ── User: "I browse gallery templates" ──

    @Test func `list returns all gallery templates`() async throws {
        let repo = MockGalleryTemplateRepository()
        given(repo).listGalleryTemplates().willReturn([
            MockRepositoryFactory.makeGalleryTemplate(id: "neon-pop", name: "Neon Pop"),
            MockRepositoryFactory.makeGalleryTemplate(id: "blue-depth", name: "Blue Depth"),
        ])

        let templates = try await repo.listGalleryTemplates()
        #expect(templates.count == 2)
        #expect(templates[0].id == "neon-pop")
        #expect(templates[1].id == "blue-depth")
    }

    // ── User: "I pick a specific gallery template" ──

    @Test func `get returns template by id`() async throws {
        let repo = MockGalleryTemplateRepository()
        given(repo).getGalleryTemplate(id: .value("neon-pop")).willReturn(
            MockRepositoryFactory.makeGalleryTemplate(id: "neon-pop", name: "Neon Pop")
        )

        let template = try await repo.getGalleryTemplate(id: "neon-pop")
        #expect(template?.id == "neon-pop")
        #expect(template?.name == "Neon Pop")
    }

    @Test func `get returns nil for unknown id`() async throws {
        let repo = MockGalleryTemplateRepository()
        given(repo).getGalleryTemplate(id: .value("unknown")).willReturn(nil)

        let template = try await repo.getGalleryTemplate(id: "unknown")
        #expect(template == nil)
    }
}
