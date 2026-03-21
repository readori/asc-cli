import ArgumentParser

struct IrisAppsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apps",
        abstract: "Manage apps via iris private API",
        subcommands: [IrisAppsList.self, IrisAppsCreate.self]
    )
}
