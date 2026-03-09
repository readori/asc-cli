import ArgumentParser

struct AppClipExperienceLocalizationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "app-clip-experience-localizations",
        abstract: "Manage App Clip default experience localizations",
        subcommands: [
            AppClipExperienceLocalizationsList.self,
            AppClipExperienceLocalizationsCreate.self,
            AppClipExperienceLocalizationsDelete.self,
        ]
    )
}
