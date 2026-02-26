import SwiftUI
import Domain

/// The main menu bar popup content.
/// Mirrors the claudebar layout: header → app pills → version cards → quick actions → footer.
struct MenuContentView: View {
    let monitor: AppStoreMonitor

    @Environment(\.appTheme) private var theme
    @State private var showSettings = false
    @State private var isHoveringRefresh = false
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Background gradient
            theme.backgroundGradient
                .ignoresSafeArea()

            // Background orbs
            if theme.showBackgroundOrbs {
                backgroundOrbs
            }

            if showSettings {
                SettingsContentView(showSettings: $showSettings, monitor: monitor)
            } else {
                mainContent
            }
        }
        .frame(width: 340)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { animateIn = true }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            if !monitor.apps.isEmpty {
                appPillsRow
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            Divider()
                .background(theme.glassBorder)
                .padding(.bottom, 12)

            versionsContent
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            quickActionsBar
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider()
                .background(theme.glassBorder)

            footerView
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center, spacing: 8) {
            // Logo / branding
            HStack(spacing: 6) {
                Image(systemName: "app.connected.to.app.below.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.accentGradient)

                Text("ASCBar")
                    .font(.system(size: 15, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
            }

            Spacer()

            // Status indicator
            if let error = monitor.lastError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.statusRemoved)
                    .help(error)
            }

            // Refresh button
            Button(action: {
                Task { await monitor.refresh() }
            }) {
                Image(systemName: monitor.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isHoveringRefresh ? theme.accentPrimary : theme.textSecondary)
                    .rotationEffect(monitor.isSyncing ? .degrees(360) : .degrees(0))
                    .animation(
                        monitor.isSyncing
                            ? .linear(duration: 1.2).repeatForever(autoreverses: false)
                            : .default,
                        value: monitor.isSyncing
                    )
            }
            .buttonStyle(.plain)
            .onHover { isHoveringRefresh = $0 }

            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - App Pills

    private var appPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(monitor.apps) { app in
                    AppPillView(
                        app: app,
                        isSelected: monitor.selectedAppId == app.id,
                        onTap: { monitor.selectApp(app.id) }
                    )
                }
            }
        }
    }

    // MARK: - Versions Content

    @ViewBuilder
    private var versionsContent: some View {
        if monitor.isSyncing && monitor.apps.isEmpty {
            loadingView
        } else if let error = monitor.lastError, monitor.apps.isEmpty {
            errorView(error)
        } else if monitor.apps.isEmpty {
            emptyAppsView
        } else {
            VStack(alignment: .leading, spacing: 10) {
                if let app = monitor.selectedApp {
                    // App info header
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.displayName)
                            .font(.system(size: 14, weight: .semibold, design: theme.fontDesign))
                            .foregroundStyle(theme.textPrimary)
                        Text(app.bundleId)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(.bottom, 4)
                }

                if monitor.selectedVersions.isEmpty && !monitor.isSyncing {
                    Text("No versions found")
                        .font(.system(size: 12, design: theme.fontDesign))
                        .foregroundStyle(theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                } else {
                    VStack(spacing: 6) {
                        ForEach(monitor.selectedVersions.prefix(6)) { version in
                            VersionCardView(version: version)
                        }
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 8)
                }
            }
        }
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActionsBar: some View {
        let editableVersion = monitor.selectedVersions.first(where: { $0.isEditable })
        let liveVersion = monitor.selectedVersions.first(where: { $0.isLive })

        if editableVersion != nil || liveVersion != nil {
            VStack(alignment: .leading, spacing: 6) {
                Text("QUICK ACTIONS")
                    .font(.system(size: 10, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.textTertiary)
                    .tracking(0.8)

                HStack(spacing: 8) {
                    if let v = editableVersion {
                        quickActionButton(
                            title: "Check Readiness",
                            symbol: "checklist",
                            command: "asc versions check-readiness --version-id \(v.id)"
                        )
                        quickActionButton(
                            title: "Submit",
                            symbol: "paperplane.fill",
                            command: "asc versions submit --version-id \(v.id)"
                        )
                    }
                    if let v = liveVersion {
                        quickActionButton(
                            title: "View Live",
                            symbol: "safari",
                            command: "asc versions list --app-id \(v.appId)"
                        )
                    }
                }
            }
        }
    }

    private func quickActionButton(title: String, symbol: String, command: String) -> some View {
        Button(action: { copyToClipboard(command) }) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: theme.fontDesign))
            }
            .foregroundStyle(theme.accentPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                    .fill(theme.accentPrimary.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                            .strokeBorder(theme.accentPrimary.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .help("Copies `\(command)` to clipboard")
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Text(monitor.lastSyncDescription)
                .font(.system(size: 10, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 11, design: theme.fontDesign))
            .foregroundStyle(theme.textTertiary)
            .buttonStyle(.plain)
        }
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
                .tint(theme.accentPrimary)
            Text("Fetching apps…")
                .font(.system(size: 12, design: theme.fontDesign))
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(theme.statusRemoved)
            Text("Could not load apps")
                .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
            Text(error)
                .font(.system(size: 11, design: theme.fontDesign))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
            Text("Run `asc auth login` in Terminal")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(theme.textTertiary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var emptyAppsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundStyle(theme.textTertiary)
            Text("No apps found")
                .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(theme.textSecondary)
            Text("Make sure `asc auth login` was run")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Background Orbs

    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.accentPrimary.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: -80, y: -60)
                .blur(radius: 30)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.accentSecondary.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: 100, y: 60)
                .blur(radius: 25)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

#Preview("Dark - Loading") {
    MenuContentView(monitor: AppStoreMonitor(repository: PreviewRepository()))
        .appThemeProvider(themeModeId: "dark")
        .frame(width: 340)
}

// MARK: - Preview Helpers

private final class PreviewRepository: AppStoreRepository {
    func fetchApps() async throws -> [ASCApp] {
        try? await Task.sleep(for: .seconds(1))
        return [
            ASCApp(id: "1", name: "MyApp Pro", bundleId: "com.example.myapp"),
            ASCApp(id: "2", name: "SecondApp", bundleId: "com.example.second"),
        ]
    }

    func fetchVersions(appId: String) async throws -> [ASCVersion] {
        [
            ASCVersion(id: "v1", appId: appId, versionString: "1.5.0", platform: "IOS", state: "READY_FOR_SALE"),
            ASCVersion(id: "v2", appId: appId, versionString: "1.6.0", platform: "IOS", state: "PREPARE_FOR_SUBMISSION"),
        ]
    }
}
