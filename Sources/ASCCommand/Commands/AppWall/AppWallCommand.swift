import ArgumentParser

struct AppWallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-wall",
        abstract: "Submit your developer profile to the asc app wall",
        subcommands: [AppWallSubmit.self]
    )
}
