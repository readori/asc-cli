import Domain
import Foundation

public struct AXeInteractionRepository: SimulatorInteractionRepository, @unchecked Sendable {
    private let axePath: String?

    public init() {
        self.axePath = Self.resolveAxePath()
    }

    public func isAvailable() -> Bool {
        axePath != nil
    }

    public func tap(udid: String, x: Int, y: Int) async throws {
        try run("tap -x \(x) -y \(y) --udid \(udid)")
    }

    public func tapById(udid: String, identifier: String) async throws {
        try run("tap --id \"\(identifier)\" --udid \(udid)")
    }

    public func tapByLabel(udid: String, label: String) async throws {
        try run("tap --label \"\(label)\" --udid \(udid)")
    }

    public func swipe(udid: String, startX: Int, startY: Int, endX: Int, endY: Int, duration: Double?, delta: Int?) async throws {
        var cmd = "swipe --start-x \(startX) --start-y \(startY) --end-x \(endX) --end-y \(endY)"
        if let duration { cmd += " --duration \(duration)" }
        if let delta { cmd += " --delta \(delta)" }
        cmd += " --udid \(udid)"
        try run(cmd)
    }

    public func gesture(udid: String, gesture: SimulatorGesture) async throws {
        try run("gesture \(gesture.rawValue) --udid \(udid)")
    }

    public func type(udid: String, text: String) async throws {
        guard let axe = axePath else { throw AXeError.notInstalled }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
        process.arguments = ["-c", "echo \"\(escaped)\" | \"\(axe)\" type --stdin --udid \(udid)"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw AXeError.executionFailed("type command failed")
        }
    }

    public func key(udid: String, keyCode: Int, duration: Double?) async throws {
        var cmd = "key \(keyCode)"
        if let duration { cmd += " --duration \(duration)" }
        cmd += " --udid \(udid)"
        try run(cmd)
    }

    public func keyCombo(udid: String, modifiers: [Int], key: Int) async throws {
        let modStr = modifiers.map(String.init).joined(separator: ",")
        try run("key-combo --modifiers \(modStr) --key \(key) --udid \(udid)")
    }

    public func button(udid: String, button: SimulatorButton) async throws {
        try run("button \(button.rawValue) --udid \(udid)")
    }

    public func describeUI(udid: String, point: String?) async throws -> String {
        var cmd = "describe-ui --udid \(udid)"
        if let point { cmd += " --point \(point)" }
        return try runCapture(cmd)
    }

    public func batch(udid: String, steps: [String]) async throws {
        let stepArgs = steps.map { "--step \"\($0)\"" }.joined(separator: " ")
        try run("batch --udid \(udid) \(stepArgs) --continue-on-error")
    }

    // MARK: - Private

    private static func resolveAxePath() -> String? {
        let candidates = ["/opt/homebrew/bin/axe", "/usr/local/bin/axe"]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) { return path }
        }
        // Try `which`
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["axe"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let output, !output.isEmpty { return output }
        }
        return nil
    }

    private func run(_ arguments: String) throws {
        guard let axe = axePath else { throw AXeError.notInstalled }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "\"\(axe)\" \(arguments)"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw AXeError.executionFailed("axe \(arguments.prefix(30))... failed with code \(process.terminationStatus)")
        }
    }

    private func runCapture(_ arguments: String) throws -> String {
        guard let axe = axePath else { throw AXeError.notInstalled }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "\"\(axe)\" \(arguments)"]
        process.standardInput = FileHandle.nullDevice
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw AXeError.executionFailed("axe \(arguments.prefix(30))... failed")
        }
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

public enum AXeError: Error, LocalizedError {
    case notInstalled
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "axe not installed. Run: brew install cameroncooke/axe/axe"
        case .executionFailed(let msg):
            return msg
        }
    }
}
