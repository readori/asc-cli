import Foundation
import Domain

/// `asc` CLI wraps all list responses in `{"data": [...]}`.
private struct DataResponse<T: Decodable>: Decodable {
    let data: [T]
}

/// Runs the installed `asc` CLI and decodes its JSON output.
public final class CLIAppStoreRepository: AppStoreRepository, @unchecked Sendable {
    private let executor: any CLIExecutor

    public init(executor: any CLIExecutor = DefaultCLIExecutor()) {
        self.executor = executor
    }

    public func fetchApps() async throws -> [ASCApp] {
        let output = try await executor.execute("asc", args: ["apps", "list", "--output", "json"])
        return try JSONDecoder().decode(DataResponse<ASCApp>.self, from: Data(output.utf8)).data
    }

    public func fetchVersions(appId: String) async throws -> [ASCVersion] {
        let output = try await executor.execute(
            "asc", args: ["versions", "list", "--app-id", appId, "--output", "json"]
        )
        return try JSONDecoder().decode(DataResponse<ASCVersion>.self, from: Data(output.utf8)).data
    }
}
