import ArgumentParser
import Domain

struct PluginsUninstall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Remove an installed plugin"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Plugin name")
    var name: String

    func run() async throws {
        let repo = ClientProvider.makePluginRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any PluginRepository) async throws {
        try await repo.uninstallPlugin(name: name)
        print("Plugin '\(name)' uninstalled.")
    }
}
