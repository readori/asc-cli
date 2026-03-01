import ArgumentParser
import Domain

struct PluginsInstall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install a plugin from a local directory"
    )

    @OptionGroup var globals: GlobalOptions

    @Argument(help: "Path to a directory containing manifest.json and a run executable")
    var path: String

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PluginRepository) async throws -> String {
        let plugin = try await repo.installPlugin(from: path)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [plugin],
            headers: ["Name", "Version", "Enabled", "Events"],
            rowMapper: { [
                $0.name,
                $0.version,
                $0.isEnabled ? "yes" : "no",
                $0.subscribedEvents.map(\.rawValue).joined(separator: ", "),
            ] }
        )
    }
}
