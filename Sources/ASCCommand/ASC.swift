import ArgumentParser

@main
struct ASC: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "asc",
        abstract: "App Store Connect CLI",
        version: ascVersion,
        subcommands: [
            AppsCommand.self,
            VersionsCommand.self,
            LocalizationsCommand.self,
            ScreenshotSetsCommand.self,
            ScreenshotsCommand.self,
            AppInfosCommand.self,
            AppInfoLocalizationsCommand.self,
            BuildsCommand.self,
            TestFlightCommand.self,
            AuthCommand.self,
            VersionCommand.self,
            TUICommand.self,
        ]
    )
}
