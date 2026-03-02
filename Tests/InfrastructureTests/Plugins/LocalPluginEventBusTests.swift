import Foundation
import Mockable
import Testing
@testable import Domain
@testable import Infrastructure

private func makePayload(event: PluginEvent = .buildUploaded) -> PluginEventPayload {
    PluginEventPayload(event: event, appId: "app-1", buildId: "build-1", timestamp: Date(timeIntervalSince1970: 0))
}

// State-capturing spy that records which plugins and events were passed to run().
private actor RunnerSpy: PluginRunner {
    private(set) var calledPluginNames: [String] = []
    private(set) var calledEvents: [PluginEvent] = []
    let shouldThrow: Bool

    init(shouldThrow: Bool = false) {
        self.shouldThrow = shouldThrow
    }

    func run(plugin: Plugin, event: PluginEvent, payload: PluginEventPayload) async throws -> PluginResult {
        calledPluginNames.append(plugin.name)
        calledEvents.append(event)
        if shouldThrow {
            throw PluginError.executionFailed(name: plugin.name, exitCode: 1)
        }
        return PluginResult(success: true, message: nil)
    }
}

@Suite("LocalPluginEventBus")
struct LocalPluginEventBusTests {

    private func makePlugin(
        name: String = "test-plugin",
        subscribedEvents: [PluginEvent] = [.buildUploaded],
        isEnabled: Bool = true
    ) -> Plugin {
        Plugin(
            id: name,
            name: name,
            version: "1.0.0",
            description: "Test plugin",
            executablePath: "/tmp/\(name)/run",
            subscribedEvents: subscribedEvents,
            isEnabled: isEnabled
        )
    }

    // MARK: - Routing

    @Test func `emit runs enabled plugin subscribed to event`() async throws {
        let mockRepo = MockPluginRepository()
        let spy = RunnerSpy()
        given(mockRepo).listPlugins().willReturn([makePlugin(name: "slack-notify", subscribedEvents: [.buildUploaded])])

        let bus = LocalPluginEventBus(pluginRepository: mockRepo, pluginRunner: spy)
        try await bus.emit(event: .buildUploaded, payload: makePayload())

        let names = await spy.calledPluginNames
        #expect(names == ["slack-notify"])
    }

    @Test func `emit skips disabled plugins`() async throws {
        let mockRepo = MockPluginRepository()
        let spy = RunnerSpy()
        given(mockRepo).listPlugins().willReturn([makePlugin(name: "disabled-plugin", subscribedEvents: [.buildUploaded], isEnabled: false)])

        let bus = LocalPluginEventBus(pluginRepository: mockRepo, pluginRunner: spy)
        try await bus.emit(event: .buildUploaded, payload: makePayload())

        let names = await spy.calledPluginNames
        #expect(names.isEmpty)
    }

    @Test func `emit skips plugins not subscribed to the event`() async throws {
        let mockRepo = MockPluginRepository()
        let spy = RunnerSpy()
        given(mockRepo).listPlugins().willReturn([makePlugin(name: "version-watcher", subscribedEvents: [.versionSubmitted])])

        let bus = LocalPluginEventBus(pluginRepository: mockRepo, pluginRunner: spy)
        try await bus.emit(event: .buildUploaded, payload: makePayload())

        let names = await spy.calledPluginNames
        #expect(names.isEmpty)
    }

    @Test func `emit runs all enabled plugins subscribed to event`() async throws {
        let mockRepo = MockPluginRepository()
        let spy = RunnerSpy()
        given(mockRepo).listPlugins().willReturn([
            makePlugin(name: "slack", subscribedEvents: [.buildUploaded]),
            makePlugin(name: "telegram", subscribedEvents: [.buildUploaded]),
        ])

        let bus = LocalPluginEventBus(pluginRepository: mockRepo, pluginRunner: spy)
        try await bus.emit(event: .buildUploaded, payload: makePayload())

        let names = await spy.calledPluginNames
        #expect(Set(names) == Set(["slack", "telegram"]))
    }

    @Test func `emit runs only subscribed plugins when list is mixed`() async throws {
        let mockRepo = MockPluginRepository()
        let spy = RunnerSpy()
        given(mockRepo).listPlugins().willReturn([
            makePlugin(name: "build-watcher", subscribedEvents: [.buildUploaded]),
            makePlugin(name: "version-watcher", subscribedEvents: [.versionSubmitted]),
            makePlugin(name: "disabled-watcher", subscribedEvents: [.buildUploaded], isEnabled: false),
        ])

        let bus = LocalPluginEventBus(pluginRepository: mockRepo, pluginRunner: spy)
        try await bus.emit(event: .buildUploaded, payload: makePayload())

        let names = await spy.calledPluginNames
        #expect(names == ["build-watcher"])
    }

    // MARK: - Error isolation

    @Test func `emit does not throw when plugin runner throws`() async throws {
        let mockRepo = MockPluginRepository()
        let spy = RunnerSpy(shouldThrow: true)
        given(mockRepo).listPlugins().willReturn([makePlugin(subscribedEvents: [.buildUploaded])])

        let bus = LocalPluginEventBus(pluginRepository: mockRepo, pluginRunner: spy)
        // Must not throw — individual plugin failures are swallowed
        try await bus.emit(event: .buildUploaded, payload: makePayload())
    }

    @Test func `emit runs remaining plugins after one fails`() async throws {
        let mockRepo = MockPluginRepository()
        let spy = RunnerSpy(shouldThrow: true)
        given(mockRepo).listPlugins().willReturn([
            makePlugin(name: "failing-plugin", subscribedEvents: [.buildUploaded]),
            makePlugin(name: "also-runs", subscribedEvents: [.buildUploaded]),
        ])

        let bus = LocalPluginEventBus(pluginRepository: mockRepo, pluginRunner: spy)
        try await bus.emit(event: .buildUploaded, payload: makePayload())

        // Both plugins attempted despite the first one failing
        let names = await spy.calledPluginNames
        #expect(Set(names) == Set(["failing-plugin", "also-runs"]))
    }

    // MARK: - Empty list

    @Test func `emit with no plugins does not invoke runner`() async throws {
        let mockRepo = MockPluginRepository()
        let spy = RunnerSpy()
        given(mockRepo).listPlugins().willReturn([])

        let bus = LocalPluginEventBus(pluginRepository: mockRepo, pluginRunner: spy)
        try await bus.emit(event: .buildUploaded, payload: makePayload())

        let names = await spy.calledPluginNames
        #expect(names.isEmpty)
    }
}
