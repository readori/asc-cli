import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite("PluginsList")
struct PluginsListTests {

    @Test func `listed plugins include all fields and affordances`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listPlugins().willReturn([
            Plugin(
                id: "slack-notify",
                name: "slack-notify",
                version: "1.0.0",
                description: "Send Slack notifications for App Store events",
                author: "Test Author",
                executablePath: "/tmp/slack-notify/run",
                subscribedEvents: [.buildUploaded, .versionSubmitted],
                isEnabled: true
            )
        ])

        let cmd = try PluginsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        // Raw string literal allows writing \/ without double-escaping
        #expect(output == #"""
        {
          "data" : [
            {
              "affordances" : {
                "disable" : "asc plugins disable --name slack-notify",
                "listPlugins" : "asc plugins list",
                "run.build.uploaded" : "asc plugins run --name slack-notify --event build.uploaded",
                "run.version.approved" : "asc plugins run --name slack-notify --event version.approved",
                "run.version.rejected" : "asc plugins run --name slack-notify --event version.rejected",
                "run.version.submitted" : "asc plugins run --name slack-notify --event version.submitted",
                "uninstall" : "asc plugins uninstall --name slack-notify"
              },
              "author" : "Test Author",
              "description" : "Send Slack notifications for App Store events",
              "executablePath" : "\/tmp\/slack-notify\/run",
              "id" : "slack-notify",
              "isEnabled" : true,
              "name" : "slack-notify",
              "subscribedEvents" : [
                "build.uploaded",
                "version.submitted"
              ],
              "version" : "1.0.0"
            }
          ]
        }
        """#)
    }

    @Test func `empty plugin list returns empty data array`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listPlugins().willReturn([])

        let cmd = try PluginsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }

    @Test func `disabled plugin affordances include enable but not disable`() async throws {
        let mockRepo = MockPluginRepository()
        given(mockRepo).listPlugins().willReturn([
            Plugin(
                id: "telegram-notify",
                name: "telegram-notify",
                version: "1.0.0",
                description: "Telegram notifications",
                executablePath: "/tmp/telegram/run",
                subscribedEvents: [.buildUploaded],
                isEnabled: false
            )
        ])

        let cmd = try PluginsList.parse(["--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"enable\" : \"asc plugins enable --name telegram-notify\""))
        #expect(!output.contains("\"disable\""))
    }
}
