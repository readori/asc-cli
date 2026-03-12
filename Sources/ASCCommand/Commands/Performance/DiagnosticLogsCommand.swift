import ArgumentParser
import Domain
import Foundation

struct DiagnosticLogsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "diagnostic-logs",
        abstract: "List diagnostic logs for a signature",
        subcommands: [DiagnosticLogsList.self]
    )
}

struct DiagnosticLogsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List diagnostic logs for a signature"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Diagnostic signature ID")
    var signatureId: String

    func run() async throws {
        let repo = try ClientProvider.makeDiagnosticsRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any DiagnosticsRepository) async throws -> String {
        let logs = try await repo.listLogs(signatureId: signatureId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            logs,
            headers: ["ID", "Bundle ID", "Version", "OS", "Device", "Event"],
            rowMapper: {
                [
                    $0.id,
                    $0.bundleId ?? "-",
                    $0.appVersion ?? "-",
                    $0.osVersion ?? "-",
                    $0.deviceType ?? "-",
                    $0.event ?? "-",
                ]
            }
        )
    }
}
