import SwiftUI
import AppKit
import Domain

/// Settings panel matching row-4-settings.html prototype.
/// Sections: Auth · Appearance · Behaviour — with action bar at bottom.
struct SettingsContentView: View {
    @Binding var showSettings: Bool
    let monitor: AppPortfolio

    @Environment(\.appTheme) private var theme
    @State private var settings = AppSettings.shared
    @State private var credInfo: CredentialInfo? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(theme.glassBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    authSection
                    appearanceSection
                    behaviourSection
                }
                .padding(.bottom, 4)
            }

            Divider().background(theme.glassBorder)
            actionBar
        }
        .task { credInfo = loadCredentials() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { showSettings = false }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                }
                .foregroundStyle(theme.accentPrimary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            // Balance spacer — same width as back button area
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Auth Section

    private var authSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Auth")

            VStack(spacing: 0) {
                // Credentials status row
                HStack(spacing: 10) {
                    Text("🔑")
                        .font(.system(size: 13))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(BaseColors.systemGreen.opacity(0.18))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Credentials")
                            .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                            .foregroundStyle(theme.textPrimary)
                        Text(credInfo != nil
                             ? "Source: file · ~/.asc/credentials.json"
                             : "Not configured")
                            .font(.system(size: 11, design: theme.fontDesign))
                            .foregroundStyle(theme.textSecondary)
                    }

                    Spacer()

                    let isActive = credInfo != nil
                    Text(isActive ? "Active" : "Missing")
                        .font(.system(size: 10, weight: .bold, design: theme.fontDesign))
                        .foregroundStyle(isActive ? BaseColors.systemGreen : BaseColors.systemRed)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill((isActive ? BaseColors.systemGreen : BaseColors.systemRed).opacity(0.15))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if let cred = credInfo {
                    rowDivider
                    authDetailRow(label: "Key ID", value: cred.keyID)
                    rowDivider
                    authDetailRow(label: "Issuer ID", value: String(cred.issuerID.prefix(10)) + "…")
                }
            }
            .background(settingsCard)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Appearance")

            HStack(spacing: 8) {
                ForEach(ThemeRegistry.all, id: \.id) { t in
                    themeSwatchButton(t)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Behaviour Section

    private var behaviourSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Behaviour")

            VStack(spacing: 0) {
                toggleRow(label: "Launch at login", isOn: $settings.launchAtLogin)
                rowDivider
                toggleRow(label: "Background orbs", isOn: $settings.backgroundOrbs)
            }
            .background(settingsCard)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            Button(action: signOut) {
                Text("Sign Out")
                    .font(.system(size: 12, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(BaseColors.systemRed)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                            .fill(theme.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                                    .stroke(theme.glassBorder, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("ASCBar v1.0.0")
                .font(.system(size: 11, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Reusable Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold, design: theme.fontDesign))
            .foregroundStyle(theme.textTertiary)
            .tracking(0.6)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    private func authDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(theme.accentPrimary)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
    }

    private func themeSwatchButton(_ t: any AppThemeProvider) -> some View {
        let isSelected = settings.themeMode == t.id
        return Button(action: { settings.themeMode = t.id }) {
            ZStack(alignment: .bottom) {
                t.backgroundGradient
                    .frame(width: 52, height: 38)

                Text(t.displayName)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
                    .padding(.bottom, 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? theme.accentPrimary : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
    }

    private var settingsCard: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .fill(theme.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(theme.glassBorder, lineWidth: 1)
            )
    }

    // MARK: - Helpers

    private func signOut() {
        let credentialsURL = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".asc/credentials.json")
        try? FileManager.default.removeItem(at: credentialsURL)
        credInfo = nil
        Task { await monitor.refresh() }
    }

    private func loadCredentials() -> CredentialInfo? {
        let url = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".asc/credentials.json")
        guard let data = try? Data(contentsOf: url),
              let stored = try? JSONDecoder().decode(StoredCredentials.self, from: data)
        else { return nil }
        return CredentialInfo(keyID: stored.keyID, issuerID: stored.issuerID)
    }
}

// MARK: - Private Types

private struct CredentialInfo {
    let keyID: String
    let issuerID: String
}

private struct StoredCredentials: Decodable {
    let keyID: String
    let issuerID: String
}
