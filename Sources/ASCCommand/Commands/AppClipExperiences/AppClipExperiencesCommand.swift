import ArgumentParser

struct AppClipExperiencesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-clip-experiences",
        abstract: "Manage App Clip default experiences",
        subcommands: [
            AppClipExperiencesList.self,
            AppClipExperiencesCreate.self,
            AppClipExperiencesDelete.self,
        ]
    )
}
