import ArgumentParser
import Domain
import Foundation

struct PluginsRun: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Manually invoke a plugin for a given event (useful for testing)"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Plugin name")
    var name: String

    @Option(name: .long, help: "Event to fire: build.uploaded, version.submitted, version.approved, version.rejected")
    var event: String

    @Option(name: .long, help: "App ID to include in the event payload")
    var appId: String?

    @Option(name: .long, help: "Version ID to include in the event payload")
    var versionId: String?

    @Option(name: .long, help: "Build ID to include in the event payload")
    var buildId: String?

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        let runner = ClientProvider.makePluginRunner()
        print(try await execute(repo: repo, runner: runner))
    }

    func execute(repo: any PluginRepository, runner: any PluginRunner) async throws -> String {
        guard let pluginEvent = PluginEvent(rawValue: event) else {
            throw ValidationError("Unknown event '\(event)'. Valid events: \(PluginEvent.allCases.map(\.rawValue).joined(separator: ", "))")
        }
        let plugin = try await repo.getPlugin(name: name)
        let payload = PluginEventPayload(
            event: pluginEvent,
            appId: appId,
            versionId: versionId,
            buildId: buildId
        )
        let result = try await runner.run(plugin: plugin, event: pluginEvent, payload: payload)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatItems(
            [result],
            headers: ["Success", "Message", "Error"],
            rowMapper: { [
                $0.success ? "yes" : "no",
                $0.message ?? "",
                $0.error ?? "",
            ] }
        )
    }
}
