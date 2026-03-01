import Domain
import Foundation

/// Executes a plugin's `run` executable as a subprocess.
///
/// Protocol (stdin/stdout JSON):
///   stdin  → `{"event":"build.uploaded","payload":{...}}`
///   stdout ← `{"success":true,"message":"Notification sent"}`
public struct ProcessPluginRunner: PluginRunner {

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func run(plugin: Plugin, event: PluginEvent, payload: PluginEventPayload) async throws -> PluginResult {
        let inputMessage = PluginInputMessage(event: event, payload: payload)
        let inputData = try encoder.encode(inputMessage)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: plugin.executablePath)
        process.arguments = []

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        stdinPipe.fileHandleForWriting.write(inputData)
        stdinPipe.fileHandleForWriting.closeFile()

        let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PluginError.executionFailed(name: plugin.name, exitCode: process.terminationStatus)
        }

        guard !outputData.isEmpty else {
            return PluginResult(success: true, message: nil)
        }

        do {
            return try decoder.decode(PluginResult.self, from: outputData)
        } catch {
            throw PluginError.invalidOutput(name: plugin.name)
        }
    }
}

// MARK: - Wire format

private struct PluginInputMessage: Encodable {
    let event: PluginEvent
    let payload: PluginEventPayload
}
