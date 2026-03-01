import Foundation
import Testing
@testable import Domain

@Suite("Plugin")
struct PluginTests {

    @Test func `plugin carries all fields`() {
        let plugin = MockRepositoryFactory.makePlugin(
            id: "slack-notify",
            name: "slack-notify",
            version: "1.0.0",
            description: "Send Slack notifications",
            author: "Test Author",
            executablePath: "/tmp/slack-notify/run",
            subscribedEvents: [.buildUploaded, .versionSubmitted],
            isEnabled: true
        )

        #expect(plugin.id == "slack-notify")
        #expect(plugin.name == "slack-notify")
        #expect(plugin.version == "1.0.0")
        #expect(plugin.description == "Send Slack notifications")
        #expect(plugin.author == "Test Author")
        #expect(plugin.executablePath == "/tmp/slack-notify/run")
        #expect(plugin.subscribedEvents == [.buildUploaded, .versionSubmitted])
        #expect(plugin.isEnabled == true)
    }

    @Test func `enabled plugin affordances include disable and run commands`() {
        let plugin = MockRepositoryFactory.makePlugin(name: "slack-notify", isEnabled: true)

        #expect(plugin.affordances["listPlugins"] == "asc plugins list")
        #expect(plugin.affordances["uninstall"] == "asc plugins uninstall --name slack-notify")
        #expect(plugin.affordances["disable"] == "asc plugins disable --name slack-notify")
        #expect(plugin.affordances["enable"] == nil)
        #expect(plugin.affordances["run.build.uploaded"] == "asc plugins run --name slack-notify --event build.uploaded")
        #expect(plugin.affordances["run.version.submitted"] == "asc plugins run --name slack-notify --event version.submitted")
    }

    @Test func `disabled plugin affordances include enable but not disable`() {
        let plugin = MockRepositoryFactory.makePlugin(name: "telegram-notify", isEnabled: false)

        #expect(plugin.affordances["enable"] == "asc plugins enable --name telegram-notify")
        #expect(plugin.affordances["disable"] == nil)
    }

    @Test func `plugin event display names match raw values`() {
        #expect(PluginEvent.buildUploaded.rawValue == "build.uploaded")
        #expect(PluginEvent.versionSubmitted.rawValue == "version.submitted")
        #expect(PluginEvent.versionApproved.rawValue == "version.approved")
        #expect(PluginEvent.versionRejected.rawValue == "version.rejected")
    }

    @Test func `plugin event payload carries all optional fields`() {
        let payload = MockRepositoryFactory.makePluginEventPayload(
            event: .buildUploaded,
            appId: "app-42",
            versionId: nil,
            buildId: "build-99"
        )

        #expect(payload.event == .buildUploaded)
        #expect(payload.appId == "app-42")
        #expect(payload.versionId == nil)
        #expect(payload.buildId == "build-99")
    }

    @Test func `plugin result carries success flag and message`() {
        let ok = MockRepositoryFactory.makePluginResult(success: true, message: "Sent to Slack")
        #expect(ok.success == true)
        #expect(ok.message == "Sent to Slack")
        #expect(ok.error == nil)

        let fail = MockRepositoryFactory.makePluginResult(success: false, message: nil, error: "Webhook URL not set")
        #expect(fail.success == false)
        #expect(fail.error == "Webhook URL not set")
        #expect(fail.message == nil)
    }

    @Test func `plugin is codable round trip`() throws {
        let plugin = MockRepositoryFactory.makePlugin()
        let data = try JSONEncoder().encode(plugin)
        let decoded = try JSONDecoder().decode(Plugin.self, from: data)
        #expect(decoded == plugin)
    }

    @Test func `plugin event payload is codable round trip`() throws {
        let payload = MockRepositoryFactory.makePluginEventPayload()
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(PluginEventPayload.self, from: data)
        #expect(decoded == payload)
    }
}
