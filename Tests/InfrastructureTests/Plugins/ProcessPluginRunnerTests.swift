import Foundation
import Testing
@testable import Domain
@testable import Infrastructure

@Suite("ProcessPluginRunner")
struct ProcessPluginRunnerTests {

    // MARK: - Helpers

    /// Creates a temporary shell script with the given body and marks it executable.
    private func makeExecutable(script: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("asc-runner-test-\(UUID().uuidString)")
        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        return url
    }

    private func makePlugin(executablePath: String, name: String = "test-plugin") -> Plugin {
        Plugin(
            id: name,
            name: name,
            version: "1.0.0",
            description: "Test plugin",
            executablePath: executablePath,
            subscribedEvents: [.buildUploaded],
            isEnabled: true
        )
    }

    private func makePayload(event: PluginEvent = .buildUploaded) -> PluginEventPayload {
        PluginEventPayload(
            event: event,
            appId: "app-1",
            buildId: "build-1",
            timestamp: Date(timeIntervalSince1970: 0)
        )
    }

    // MARK: - Tests

    @Test func `run returns success result with message when plugin outputs valid JSON`() async throws {
        let exec = try makeExecutable(script: """
        #!/bin/sh
        printf '{"success":true,"message":"Notification sent"}'
        """)
        let runner = ProcessPluginRunner()

        let result = try await runner.run(plugin: makePlugin(executablePath: exec.path), event: .buildUploaded, payload: makePayload())

        #expect(result.success == true)
        #expect(result.message == "Notification sent")
        #expect(result.error == nil)
    }

    @Test func `run returns failure result with error field`() async throws {
        let exec = try makeExecutable(script: """
        #!/bin/sh
        printf '{"success":false,"error":"Webhook URL not configured"}'
        """)
        let runner = ProcessPluginRunner()

        let result = try await runner.run(plugin: makePlugin(executablePath: exec.path), event: .buildUploaded, payload: makePayload())

        #expect(result.success == false)
        #expect(result.error == "Webhook URL not configured")
        #expect(result.message == nil)
    }

    @Test func `run returns success with nil message when stdout is empty`() async throws {
        let exec = try makeExecutable(script: """
        #!/bin/sh
        # Produce no output
        """)
        let runner = ProcessPluginRunner()

        let result = try await runner.run(plugin: makePlugin(executablePath: exec.path), event: .buildUploaded, payload: makePayload())

        #expect(result.success == true)
        #expect(result.message == nil)
    }

    @Test func `run throws executionFailed when process exits with non-zero code`() async throws {
        let exec = try makeExecutable(script: """
        #!/bin/sh
        exit 1
        """)
        let runner = ProcessPluginRunner()

        await #expect(throws: PluginError.self) {
            _ = try await runner.run(plugin: makePlugin(executablePath: exec.path), event: .buildUploaded, payload: makePayload())
        }
    }

    @Test func `run throws invalidOutput when plugin returns malformed JSON`() async throws {
        let exec = try makeExecutable(script: """
        #!/bin/sh
        printf 'not-valid-json'
        """)
        let runner = ProcessPluginRunner()

        await #expect(throws: PluginError.self) {
            _ = try await runner.run(plugin: makePlugin(executablePath: exec.path), event: .buildUploaded, payload: makePayload())
        }
    }

    @Test func `run sends event raw value in stdin JSON payload`() async throws {
        // Script reads stdin and checks whether the expected event raw value is present
        let exec = try makeExecutable(script: """
        #!/bin/sh
        input=$(cat)
        if printf '%s' "$input" | grep -q '"version.submitted"'; then
            printf '{"success":true,"message":"event found"}'
        else
            printf '{"success":false,"error":"expected version.submitted in stdin"}'
        fi
        """)
        let runner = ProcessPluginRunner()

        let result = try await runner.run(
            plugin: makePlugin(executablePath: exec.path),
            event: .versionSubmitted,
            payload: makePayload(event: .versionSubmitted)
        )

        #expect(result.success == true)
        #expect(result.message == "event found")
    }

    @Test func `run with exit code 2 includes exit code in error`() async throws {
        let exec = try makeExecutable(script: """
        #!/bin/sh
        exit 2
        """)
        let runner = ProcessPluginRunner()

        await #expect(throws: PluginError.self) {
            _ = try await runner.run(plugin: makePlugin(executablePath: exec.path, name: "failing-plugin"), event: .buildUploaded, payload: makePayload())
        }
    }
}
