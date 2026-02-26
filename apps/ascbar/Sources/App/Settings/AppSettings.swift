import Foundation
import ServiceManagement

/// Observable settings manager for ASCBar preferences.
@MainActor
@Observable
public final class AppSettings {
    public static let shared = AppSettings()

    // MARK: - Theme

    public var themeMode: String {
        didSet { UserDefaults.standard.set(themeMode, forKey: Keys.themeMode) }
    }

    // MARK: - Launch at Login

    public var launchAtLogin: Bool {
        didSet {
            guard !isInitializing else { return }
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }

    // MARK: - Background Sync

    public var backgroundSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(backgroundSyncEnabled, forKey: Keys.backgroundSyncEnabled) }
    }

    public var backgroundSyncInterval: TimeInterval {
        didSet { UserDefaults.standard.set(backgroundSyncInterval, forKey: Keys.backgroundSyncInterval) }
    }

    // MARK: - Init

    private var isInitializing = true

    private init() {
        self.themeMode = UserDefaults.standard.string(forKey: Keys.themeMode) ?? "dark"
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.backgroundSyncEnabled = UserDefaults.standard.object(forKey: Keys.backgroundSyncEnabled) as? Bool ?? false
        self.backgroundSyncInterval = UserDefaults.standard.object(forKey: Keys.backgroundSyncInterval) as? TimeInterval ?? 60
        self.isInitializing = false
    }
}

// MARK: - Keys

private extension AppSettings {
    enum Keys {
        static let themeMode = "ascbar.themeMode"
        static let backgroundSyncEnabled = "ascbar.backgroundSyncEnabled"
        static let backgroundSyncInterval = "ascbar.backgroundSyncInterval"
    }
}
