import SwiftUI
import Domain
import Infrastructure

@main
struct ASCBarApp: App {
    @State private var monitor: AppStoreMonitor
    @State private var settings = AppSettings.shared

    init() {
        let repository = CLIAppStoreRepository()
        _monitor = State(initialValue: AppStoreMonitor(repository: repository))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(monitor: monitor)
                .appThemeProvider(themeModeId: settings.themeMode)
                .task {
                    await monitor.refresh()
                    if settings.backgroundSyncEnabled {
                        monitor.startMonitoring(interval: settings.backgroundSyncInterval)
                    }
                }
                .onChange(of: settings.backgroundSyncEnabled) { _, enabled in
                    if enabled {
                        monitor.startMonitoring(interval: settings.backgroundSyncInterval)
                    } else {
                        monitor.stopMonitoring()
                    }
                }
        } label: {
            StatusBarIcon(status: monitor.overallStatus, isSyncing: monitor.isSyncing)
                .appThemeProvider(themeModeId: settings.themeMode)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Status Bar Icon

/// The menu bar icon. Shows app status with an animated spinner when syncing.
struct StatusBarIcon: View {
    let status: AppStatus
    let isSyncing: Bool

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 3) {
            if isSyncing {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.statusColor(for: status).opacity(0.7))
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(iconColor)
            }
        }
    }

    private var iconName: String {
        switch status {
        case .live:       return "app.badge.checkmark.fill"
        case .editable:   return "app.fill"
        case .pending:    return "clock.badge.fill"
        case .removed:    return "app.badge.fill"
        case .processing: return "app.fill"
        }
    }

    private var iconColor: Color {
        theme.statusColor(for: status)
    }
}
