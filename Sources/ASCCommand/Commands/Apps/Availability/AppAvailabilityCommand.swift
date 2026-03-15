import ArgumentParser

struct AppAvailabilityCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-availability",
        abstract: "Manage app territory availability",
        subcommands: [
            AppAvailabilityGet.self,
        ],
        defaultSubcommand: AppAvailabilityGet.self
    )
}
