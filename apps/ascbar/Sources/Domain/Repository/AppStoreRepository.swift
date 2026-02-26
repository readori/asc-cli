#if MOCKING
@_exported import Mockable
#endif

/// Repository for fetching App Store Connect data via the `asc` CLI.
#if MOCKING
@Mockable
#endif
public protocol AppStoreRepository: Sendable {
    func fetchApps() async throws -> [ASCApp]
    func fetchVersions(appId: String) async throws -> [ASCVersion]
}
