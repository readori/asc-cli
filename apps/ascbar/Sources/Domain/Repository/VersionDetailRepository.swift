#if MOCKING
@_exported import Mockable
#endif

/// Repository for version detail operations — readiness checks and localization editing.
#if MOCKING
@Mockable
#endif
public protocol VersionDetailRepository: Sendable {
    func fetchReadiness(versionId: String) async throws -> VersionReadinessResult
    func fetchLocalizations(versionId: String) async throws -> [LocalizationSummary]
    /// Updates any subset of localization text fields. Only non-nil arguments are sent to the API.
    func updateLocalization(
        localizationId: String,
        whatsNew: String?,
        description: String?,
        keywords: String?,
        marketingUrl: String?,
        supportUrl: String?,
        promotionalText: String?
    ) async throws
}
