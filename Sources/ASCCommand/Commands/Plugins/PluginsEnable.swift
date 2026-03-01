import ArgumentParser
import Domain

struct PluginsEnable: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "enable",
        abstract: "Enable a disabled plugin"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Plugin name")
    var name: String

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any PluginRepository) async throws -> String {
        let plugin = try await repo.enablePlugin(name: name)
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
