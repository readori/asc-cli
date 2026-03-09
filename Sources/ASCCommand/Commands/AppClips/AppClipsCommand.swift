import ArgumentParser

struct AppClipsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-clips",
        abstract: "Manage App Clips",
        subcommands: [AppClipsList.self]
    )
}
