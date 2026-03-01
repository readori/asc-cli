import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("PluginsRun")
struct PluginsRunTests {

    private func makePlugin(name: String = "slack-notify") -> Plugin {
        Plugin(
            id: name,
            name: name,
            version: "1.0.0",
            description: "Test plugin",
            executablePath: "/tmp/\(name)/run",
            subscribedEvents: [.buildUploaded],
            isEnabled: true
        )
    }

    @Test func `running a plugin returns success result`() async throws {
        let mockRepo = MockPluginRepository()
        let mockRunner = MockPluginRunner()

        given(mockRepo).getPlugin(name: .value("slack-notify")).willReturn(makePlugin())
        given(mockRunner).run(plugin: .any, event: .any, payload: .any)
            .willReturn(PluginResult(success: true, message: "Notification sent"))

        let cmd = try PluginsRun.parse(["--name", "slack-notify", "--event", "build.uploaded", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo, runner: mockRunner)

        #expect(output == """
        [
          {
            "message" : "Notification sent",
            "success" : true
          }
        ]
        """)
    }

    @Test func `running a plugin with error returns failure result`() async throws {
        let mockRepo = MockPluginRepository()
        let mockRunner = MockPluginRunner()

        given(mockRepo).getPlugin(name: .value("bad-plugin")).willReturn(makePlugin(name: "bad-plugin"))
        given(mockRunner).run(plugin: .any, event: .any, payload: .any)
            .willReturn(PluginResult(success: false, error: "Webhook URL not set"))

        let cmd = try PluginsRun.parse(["--name", "bad-plugin", "--event", "version.submitted", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo, runner: mockRunner)

        #expect(output == """
        [
          {
            "error" : "Webhook URL not set",
            "success" : false
          }
        ]
        """)
    }

    @Test func `running plugin with unknown event throws validation error`() async throws {
        let mockRepo = MockPluginRepository()
        let mockRunner = MockPluginRunner()

        let cmd = try PluginsRun.parse(["--name", "slack-notify", "--event", "unknown.event"])
        await #expect(throws: (any Error).self) {
            _ = try await cmd.execute(repo: mockRepo, runner: mockRunner)
        }
    }
}
