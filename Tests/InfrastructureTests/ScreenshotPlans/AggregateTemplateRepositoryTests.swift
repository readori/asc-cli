import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite("AggregateTemplateRepository")
struct AggregateTemplateRepositoryTests {

    @Test func `empty repository returns no templates`() async throws {
        let repo = AggregateTemplateRepository()
        let templates = try await repo.listTemplates(size: nil)
        #expect(templates.isEmpty)
    }

    @Test func `registered provider templates are returned`() async throws {
        let repo = AggregateTemplateRepository()
        let provider = StubTemplateProvider(providerId: "test", templates: [
            MockRepositoryFactory.makeScreenshotTemplate(id: "t-1", name: "Template One"),
            MockRepositoryFactory.makeScreenshotTemplate(id: "t-2", name: "Template Two"),
        ])
        await repo.register(provider: provider)

        let templates = try await repo.listTemplates(size: nil)
        #expect(templates.count == 2)
        #expect(templates[0].id == "t-1")
        #expect(templates[1].id == "t-2")
    }

    @Test func `multiple providers are aggregated`() async throws {
        let repo = AggregateTemplateRepository()
        await repo.register(provider: StubTemplateProvider(providerId: "a", templates: [
            MockRepositoryFactory.makeScreenshotTemplate(id: "a-1"),
        ]))
        await repo.register(provider: StubTemplateProvider(providerId: "b", templates: [
            MockRepositoryFactory.makeScreenshotTemplate(id: "b-1"),
            MockRepositoryFactory.makeScreenshotTemplate(id: "b-2"),
        ]))

        let templates = try await repo.listTemplates(size: nil)
        #expect(templates.count == 3)
    }

    @Test func `list filters by size`() async throws {
        let repo = AggregateTemplateRepository()
        await repo.register(provider: StubTemplateProvider(providerId: "test", templates: [
            MockRepositoryFactory.makeScreenshotTemplate(id: "portrait-1", supportedSizes: [.portrait]),
            MockRepositoryFactory.makeScreenshotTemplate(id: "landscape-1", supportedSizes: [.landscape]),
            MockRepositoryFactory.makeScreenshotTemplate(id: "both-1", supportedSizes: [.portrait, .landscape]),
        ]))

        let portrait = try await repo.listTemplates(size: .portrait)
        #expect(portrait.count == 2)
        #expect(portrait.contains { $0.id == "portrait-1" })
        #expect(portrait.contains { $0.id == "both-1" })

        let landscape = try await repo.listTemplates(size: .landscape)
        #expect(landscape.count == 2)
        #expect(landscape.contains { $0.id == "landscape-1" })
        #expect(landscape.contains { $0.id == "both-1" })
    }

    @Test func `get template by id finds across providers`() async throws {
        let repo = AggregateTemplateRepository()
        await repo.register(provider: StubTemplateProvider(providerId: "a", templates: [
            MockRepositoryFactory.makeScreenshotTemplate(id: "a-1", name: "From A"),
        ]))
        await repo.register(provider: StubTemplateProvider(providerId: "b", templates: [
            MockRepositoryFactory.makeScreenshotTemplate(id: "b-1", name: "From B"),
        ]))

        let found = try await repo.getTemplate(id: "b-1")
        #expect(found?.name == "From B")

        let notFound = try await repo.getTemplate(id: "nope")
        #expect(notFound == nil)
    }
}

// MARK: - Test Helper

private struct StubTemplateProvider: TemplateProvider {
    let providerId: String
    let _templates: [ScreenshotTemplate]

    init(providerId: String, templates: [ScreenshotTemplate]) {
        self.providerId = providerId
        self._templates = templates
    }

    func templates() async throws -> [ScreenshotTemplate] {
        _templates
    }
}
