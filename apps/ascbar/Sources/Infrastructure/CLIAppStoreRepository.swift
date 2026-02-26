import Foundation
import Domain

/// Implements `AppStoreRepository` by running the `asc` CLI and decoding its JSON output.
public final class CLIAppStoreRepository: AppStoreRepository, @unchecked Sendable {
    private let executor: any CLIExecutor

    public init(executor: any CLIExecutor = DefaultCLIExecutor()) {
        self.executor = executor
    }

    public func fetchApps() async throws -> [ASCApp] {
        let output = try await executor.execute("asc", args: ["apps", "list", "--output", "json"])
        let data = Data(output.utf8)
        return try JSONDecoder().decode([ASCApp].self, from: data)
    }

    public func fetchVersions(appId: String) async throws -> [ASCVersion] {
        let output = try await executor.execute(
            "asc",
            args: ["versions", "list", "--app-id", appId, "--output", "json"]
        )
        let data = Data(output.utf8)
        return try JSONDecoder().decode([ASCVersion].self, from: data)
    }
}
