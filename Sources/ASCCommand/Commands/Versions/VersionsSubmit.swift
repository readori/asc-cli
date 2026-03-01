import ArgumentParser
import Domain

struct VersionsSubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submit",
        abstract: "Submit an App Store version for review"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store Version ID")
    var versionId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubmissionRepository()
        let eventBus = ClientProvider.makePluginEventBus()
        print(try await execute(repo: repo, eventBus: eventBus))
    }

    func execute(repo: any SubmissionRepository, eventBus: (any PluginEventBus)? = nil) async throws -> String {
        let submission = try await repo.submitVersion(versionId: versionId)

        try await eventBus?.emit(
            event: .versionSubmitted,
            payload: PluginEventPayload(
                event: .versionSubmitted,
                appId: submission.appId,
                versionId: versionId
            )
        )

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [submission],
            headers: ["ID", "Platform", "State"],
            rowMapper: { [$0.id, $0.platform.displayName, $0.state.displayName] }
        )
    }
}
