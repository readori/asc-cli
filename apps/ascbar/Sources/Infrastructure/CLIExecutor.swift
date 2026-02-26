import Foundation

// MARK: - Protocol

/// Runs shell commands and captures their output.
public protocol CLIExecutor: Sendable {
    /// Locates a binary by name, returning its full path or nil.
    func locate(binary: String) -> String?
    /// Executes a binary with arguments and returns stdout.
    func execute(_ binary: String, args: [String]) async throws -> String
}

// MARK: - Errors

public enum CLIError: Error, LocalizedError {
    case binaryNotFound(String)
    case nonZeroExit(code: Int, output: String)

    public var errorDescription: String? {
        switch self {
        case .binaryNotFound(let binary):
            return "'\(binary)' not found. Run `brew install hanrenwei/tap/asc` or `swift run asc`."
        case .nonZeroExit(let code, let output):
            return "Exit \(code): \(output)"
        }
    }
}

// MARK: - Default Implementation

public struct DefaultCLIExecutor: CLIExecutor {
    public init() {}

    public func locate(binary: String) -> String? {
        let home = NSHomeDirectory()
        let candidates = [
            "/opt/homebrew/bin/\(binary)",
            "/usr/local/bin/\(binary)",
            "\(home)/.local/bin/\(binary)",
            "\(home)/.mint/bin/\(binary)",
            "/usr/bin/\(binary)",
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return which(binary)
    }

    private func which(_ binary: String) -> String? {
        let p = Process()
        let pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        p.arguments = [binary]
        p.standardOutput = pipe
        p.standardError = Pipe()
        try? p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return out?.isEmpty == false ? out : nil
    }

    public func execute(_ binary: String, args: [String]) async throws -> String {
        guard let binaryPath = locate(binary: binary) else {
            throw CLIError.binaryNotFound(binary)
        }
        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()

            process.executableURL = URL(fileURLWithPath: binaryPath)
            process.arguments = args
            process.standardOutput = stdout
            process.standardError = stderr

            try process.run()
            process.waitUntilExit()

            let outData = stdout.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outData, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                let errOutput = String(data: errData, encoding: .utf8) ?? ""
                throw CLIError.nonZeroExit(
                    code: Int(process.terminationStatus),
                    output: errOutput.isEmpty ? output : errOutput
                )
            }
            return output
        }.value
    }
}
