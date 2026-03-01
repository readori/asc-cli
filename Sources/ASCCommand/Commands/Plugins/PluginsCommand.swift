import ArgumentParser

struct PluginsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "plugins",
        abstract: "Manage ASC plugins that extend CLI behaviour with custom event handlers",
        subcommands: [
            PluginsList.self,
            PluginsInstall.self,
            PluginsUninstall.self,
            PluginsEnable.self,
            PluginsDisable.self,
            PluginsRun.self,
        ]
    )
}
