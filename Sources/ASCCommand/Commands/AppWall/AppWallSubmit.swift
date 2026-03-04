import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AppWallSubmit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "submit",
        abstract: "Add yourself to the asc app wall by opening a pull request on GitHub"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Your Apple developer display name")
    var developer: String

    @Option(name: .long, help: "Your Apple developer/seller ID (from iTunes lookup)")
    var developerId: String

    @Option(name: .long, help: "Your GitHub username")
    var github: String

    @Option(name: .long, help: "Your X (Twitter) handle (optional)")
    var x: String?

    @Option(name: .long, help: "GitHub personal access token (or set GITHUB_TOKEN)")
    var githubToken: String?

    func run() async throws {
        let token = try resolveGitHubToken()
        let repo = GitHubAppWallRepository(token: token)
        print(try await execute(repo: repo))
    }

    func execute(repo: any AppWallRepository) async throws -> String {
        let entry = AppWallEntry(
            developer: developer,
            developerId: developerId,
            github: github,
            x: x
        )
        let submission = try await repo.submit(entry: entry)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [submission],
            headers: ["PR #", "Title", "URL"],
            rowMapper: { [String($0.prNumber), $0.title, $0.prUrl] }
        )
    }

    // MARK: - Token resolution

    private func resolveGitHubToken() throws -> String {
        if let token = githubToken, !token.isEmpty { return token }
        if let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"], !token.isEmpty { return token }
        if let token = runGHAuthToken(), !token.isEmpty { return token }
        throw ValidationError(
            "GitHub token required. " +
            "Pass --github-token, set GITHUB_TOKEN, or run `gh auth login`."
        )
    }

    private func runGHAuthToken() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh", "auth", "token"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
