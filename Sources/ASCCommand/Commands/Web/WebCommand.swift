import ArgumentParser
import Foundation
import Domain
import Infrastructure
import ASCPlugin

struct WebServerCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web-server",
        abstract: "Start the local API server for ASC web apps"
    )

    @Option(name: .long, help: "Port to listen on (default: 8420)")
    var port: Int = 8420

    func run() async throws {
        let server = ASCWebServer(port: port, commandRunner: Self.runCommand)
        try await server.run()
    }

    /// Execute a CLI command via subprocess.
    static func runCommand(_ command: String) async -> (String, Int) {
        let ascBin = ProcessInfo.processInfo.arguments[0]
        let parts = command.split(separator: " ").map(String.init)
        let args = parts.first == "asc" ? Array(parts.dropFirst()) : parts

        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: ascBin)
                process.arguments = args
                process.environment = ProcessInfo.processInfo.environment

                let stdout = Pipe()
                process.standardOutput = stdout
                process.standardError = FileHandle.nullDevice

                // Collect stdout on background thread to prevent pipe buffer deadlock
                var outputData = Data()
                let readQueue = DispatchQueue(label: "asc.pipe.read")
                stdout.fileHandleForReading.readabilityHandler = { handle in
                    let chunk = handle.availableData
                    if chunk.isEmpty {
                        stdout.fileHandleForReading.readabilityHandler = nil
                    } else {
                        readQueue.sync { outputData.append(chunk) }
                    }
                }

                do {
                    try process.run()
                    process.waitUntilExit()
                    // Give the readability handler a moment to flush
                    readQueue.sync {}
                    stdout.fileHandleForReading.readabilityHandler = nil
                    let remaining = stdout.fileHandleForReading.readDataToEndOfFile()
                    readQueue.sync { outputData.append(remaining) }
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    continuation.resume(returning: (output.trimmingCharacters(in: .whitespacesAndNewlines), Int(process.terminationStatus)))
                } catch {
                    continuation.resume(returning: (error.localizedDescription, 1))
                }
            }
        }
    }
}
