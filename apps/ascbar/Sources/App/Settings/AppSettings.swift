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

    // MARK: - Background Orbs

    public var backgroundOrbs: Bool {
        didSet { UserDefaults.standard.set(backgroundOrbs, forKey: Keys.backgroundOrbs) }
    }

    // MARK: - Init

    private var isInitializing = true

    private init() {
        self.themeMode = UserDefaults.standard.string(forKey: Keys.themeMode) ?? "dark"
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.backgroundOrbs = UserDefaults.standard.object(forKey: Keys.backgroundOrbs) as? Bool ?? true
        self.isInitializing = false
    }
}

// MARK: - Keys

private extension AppSettings {
    enum Keys {
        static let themeMode = "ascbar.themeMode"
        static let backgroundOrbs = "ascbar.backgroundOrbs"
    }
}
