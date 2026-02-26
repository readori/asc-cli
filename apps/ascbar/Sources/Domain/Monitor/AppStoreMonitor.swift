import Foundation
import Observation

/// The main domain service that coordinates App Store Connect data monitoring.
/// Fetches apps and versions via the `asc` CLI, drives UI state.
@Observable
public final class AppStoreMonitor: @unchecked Sendable {

    // MARK: - Published State

    public var apps: [ASCApp] = []
    public var versions: [ASCVersion] = []
    public var selectedAppId: String? = nil
    public var isSyncing: Bool = false
    public var lastError: String? = nil
    public var lastSyncDate: Date? = nil

    // MARK: - Private

    private let repository: any AppStoreRepository
    private var monitoringTask: Task<Void, Never>?

    // MARK: - Init

    public init(repository: any AppStoreRepository) {
        self.repository = repository
    }

    // MARK: - Computed

    public var selectedApp: ASCApp? {
        apps.first { $0.id == selectedAppId }
    }

    public var selectedVersions: [ASCVersion] {
        guard let appId = selectedAppId else { return [] }
        return versions.filter { $0.appId == appId }
    }

    /// The overall status of the selected app derived from its non-removed versions.
    public var overallStatus: AppStatus {
        let active = selectedVersions.filter { $0.appStatus != .removed }
        if active.isEmpty { return .processing }
        if active.contains(where: { $0.appStatus == .live }) { return .live }
        if active.contains(where: { $0.appStatus == .pending }) { return .pending }
        if active.contains(where: { $0.appStatus == .editable }) { return .editable }
        return .processing
    }

    public var lastSyncDescription: String {
        guard let date = lastSyncDate else { return "Never synced" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    // MARK: - Operations

    /// Fetches apps and versions for the selected app.
    public func refresh() async {
        isSyncing = true
        lastError = nil
        defer { isSyncing = false }

        do {
            let fetchedApps = try await repository.fetchApps()
            apps = fetchedApps

            // Auto-select first app if none selected or previous selection gone
            if selectedAppId == nil || !apps.contains(where: { $0.id == selectedAppId }) {
                selectedAppId = apps.first?.id
            }

            if let appId = selectedAppId {
                versions = try await repository.fetchVersions(appId: appId)
            }
            lastSyncDate = Date()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Switches to a different app and fetches its versions.
    public func selectApp(_ appId: String) {
        guard appId != selectedAppId else { return }
        selectedAppId = appId
        Task {
            do {
                isSyncing = true
                defer { isSyncing = false }
                versions = try await repository.fetchVersions(appId: appId)
                lastSyncDate = Date()
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    /// Starts periodic background monitoring at the given interval.
    public func startMonitoring(interval: TimeInterval = 60) {
        monitoringTask?.cancel()
        monitoringTask = Task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await refresh()
            }
        }
    }

    /// Stops periodic background monitoring.
    public func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
}
