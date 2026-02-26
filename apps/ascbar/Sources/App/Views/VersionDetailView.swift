import SwiftUI
import AppKit
import Domain

/// Screen 5 — version detail: state banner, info rows, CLI commands, and submit/check actions.
struct VersionDetailView: View {
    let appName: String
    let version: ASCVersion
    let detailRepository: any VersionDetailRepository
    let onOpenReadiness: () -> Void
    let onOpenLocalizations: () -> Void
    let onBack: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var localizationCount: Int? = nil
    @State private var copiedCommandId: String? = nil

    private var cliCommands: [(id: String, cmd: String)] {
        [
            ("check",    "asc versions check-readiness --version-id \(version.id)"),
            ("submit",   "asc versions submit --version-id \(version.id)"),
            ("setbuild", "asc versions set-build --version-id \(version.id)"),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    statusBanner
                    infoCard
                    cliCommandsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 440)
            actionBar
        }
        .task { await loadLocalizationCount() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
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

            Text("\(appName) \(version.versionString)")
                .font(.system(size: 14, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Status Banner

    private var statusBanner: some View {
        let color = theme.statusColor(for: version.appStatus)
        return HStack(spacing: 10) {
            Image(systemName: stateBannerIcon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(version.stateDisplayName)
                    .font(.system(size: 13, weight: .bold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
                Text(stateDescription)
                    .font(.system(size: 11, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var stateBannerIcon: String {
        switch version.appStatus {
        case .live:       return "checkmark.circle.fill"
        case .editable:   return "doc.badge.plus"
        case .pending:    return "clock.fill"
        case .processing: return "gear"
        case .removed:    return "minus.circle.fill"
        }
    }

    private var stateDescription: String {
        switch version.appStatus {
        case .editable:   return "Version is editable — ready to link a build and submit."
        case .live:       return "This version is live on the App Store."
        case .pending:    return "Version is under Apple review."
        case .processing: return "Version is being processed."
        case .removed:    return "Version has been removed from sale."
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(spacing: 0) {
            // Platform row
            HStack(spacing: 10) {
                iconBox(symbol: platformIcon, color: BaseColors.systemBlue)
                Text("Platform")
                    .font(.system(size: 13, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text(version.platformDisplayName)
                    .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            rowDivider

            // Build row
            HStack(spacing: 10) {
                iconBox(symbol: "hammer.fill", color: BaseColors.systemGreen)
                Text("Build")
                    .font(.system(size: 13, design: theme.fontDesign))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                if let buildId = version.buildId {
                    Text(buildId)
                        .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                        .foregroundStyle(theme.textPrimary)
                } else {
                    statusBadge("Not attached", color: BaseColors.systemOrange)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            rowDivider

            // Localizations row — tappable
            Button(action: onOpenLocalizations) {
                HStack(spacing: 10) {
                    iconBox(symbol: "globe", color: BaseColors.systemPurple)
                    Text("Localizations")
                        .font(.system(size: 13, design: theme.fontDesign))
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    if let count = localizationCount {
                        Text("\(count) locale\(count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                            .foregroundStyle(theme.textPrimary)
                    } else {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 20, height: 16)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(card)
    }

    // MARK: - CLI Commands

    private var cliCommandsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CLI COMMANDS")
                .font(.system(size: 11, weight: .bold, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)
                .tracking(0.6)

            ForEach(cliCommands, id: \.id) { item in
                cliRow(id: item.id, command: item.cmd)
            }
        }
        .padding(.bottom, 2)
    }

    private func cliRow(id: String, command: String) -> some View {
        let isCopied = copiedCommandId == id
        return HStack(spacing: 8) {
            Text(command)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(theme.textMono)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            Button { copyCommand(command, id: id) } label: {
                Text(isCopied ? "✓ Copied!" : "Copy")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isCopied ? theme.statusLive : theme.accentPrimary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill((isCopied ? theme.statusLive : theme.accentPrimary).opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke((isCopied ? theme.statusLive : theme.accentPrimary).opacity(0.25), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: isCopied)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.codeBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.textMono.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            if version.isEditable {
                submitButton
            }
            checkButton
            Spacer()
            closeButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    private var submitButton: some View {
        Button { copyCommand("asc versions submit --version-id \(version.id)", id: "submit") } label: {
            HStack(spacing: 4) {
                Text("🚀").font(.system(size: 11))
                Text("Submit")
                    .font(.system(size: 12, weight: .bold, design: theme.fontDesign))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(red: 1, green: 0.624, blue: 0.039),
                                 Color(red: 1, green: 0.420, blue: 0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: BaseColors.systemOrange.opacity(0.35), radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var checkButton: some View {
        Button(action: onOpenReadiness) {
            HStack(spacing: 5) {
                Image(systemName: "checklist")
                    .font(.system(size: 10, weight: .bold))
                Text("Check")
                    .font(.system(size: 12, weight: .bold, design: theme.fontDesign))
            }
            .foregroundStyle(theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(theme.glassBackground)
                    .overlay(Capsule().stroke(theme.glassBorder, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button(action: onBack) {
            ZStack {
                Circle()
                    .fill(theme.glassBackground)
                    .overlay(Circle().stroke(theme.glassBorder, lineWidth: 1))
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.textSecondary)
            }
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func iconBox(symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
            )
    }

    private func statusBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: theme.fontDesign))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
                    .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
            )
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(theme.dividerColor)
            .frame(height: 1)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: theme.cardCornerRadius)
            .fill(theme.glassBackground)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(theme.glassBorder, lineWidth: 1)
            )
    }

    private var platformIcon: String {
        switch version.platform {
        case "IOS", "WATCH_OS", "VISION_OS": return "iphone"
        case "TV_OS": return "tv"
        default: return "laptopcomputer"
        }
    }

    private func copyCommand(_ command: String, id: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        withAnimation { copiedCommandId = id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { if copiedCommandId == id { copiedCommandId = nil } }
        }
    }

    private func loadLocalizationCount() async {
        do {
            let locs = try await detailRepository.fetchLocalizations(versionId: version.id)
            localizationCount = locs.count
        } catch {
            localizationCount = 0
        }
    }
}

// MARK: - Preview

#Preview("Version Detail — Prepare for Submission") {
    VersionDetailView(
        appName: "ASCBar",
        version: ASCVersion(id: "v21", appId: "app1", versionString: "2.1.0", platform: "MAC_OS",
                            state: "PREPARE_FOR_SUBMISSION"),
        detailRepository: PreviewVersionDetailRepository(),
        onOpenReadiness: {},
        onOpenLocalizations: {},
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "dark")
}

#Preview("Version Detail — Ready for Sale") {
    VersionDetailView(
        appName: "ASCBar",
        version: ASCVersion(id: "v20", appId: "app1", versionString: "2.0.1", platform: "MAC_OS",
                            state: "READY_FOR_SALE"),
        detailRepository: PreviewVersionDetailRepository(),
        onOpenReadiness: {},
        onOpenLocalizations: {},
        onBack: {}
    )
    .frame(width: 400)
    .appThemeProvider(themeModeId: "dark")
}

// MARK: - Preview Helpers

struct PreviewVersionDetailRepository: VersionDetailRepository {
    func fetchReadiness(versionId: String) async throws -> VersionReadinessResult {
        try await Task.sleep(for: .milliseconds(800))
        return VersionReadinessResult(
            versionId: versionId,
            versionString: "2.1.0",
            isReadyToSubmit: false,
            buildLabel: nil,
            mustFix: [
                ReadinessItem(id: "build", title: "No Build Attached",
                              description: "Link a processed build before submitting",
                              fixAction: .copyCommand("asc builds list --app-id app1")),
                ReadinessItem(id: "pricing", title: "Pricing Not Set",
                              description: "Configure app pricing for required territories",
                              fixAction: nil),
            ],
            shouldFix: [
                ReadinessItem(id: "whatsNew", title: "Missing What's New (EN)",
                              description: "Release notes empty for English locale",
                              fixAction: .navigateToLocalizations),
            ],
            passing: [
                ReadinessItem(id: "state", title: "Version State — editable",
                              description: "Version is in an editable state"),
                ReadinessItem(id: "reviewContact", title: "Review Contact set",
                              description: "Review contact is configured"),
                ReadinessItem(id: "screenshots", title: "Screenshots uploaded",
                              description: "All required screenshot sets are present"),
            ]
        )
    }

    func fetchLocalizations(versionId: String) async throws -> [LocalizationSummary] {
        try await Task.sleep(for: .milliseconds(600))
        return [
            LocalizationSummary(id: "l1", locale: "en-US", isPrimary: true,
                                whatsNew: "Bug fixes and improvements.",
                                description: "A powerful app store manager.",
                                keywords: "app store, asc, developer"),
            LocalizationSummary(id: "l2", locale: "zh-Hans", isPrimary: false),
            LocalizationSummary(id: "l3", locale: "ja", isPrimary: false,
                                whatsNew: "バグ修正と改善。"),
        ]
    }

    func updateLocalization(
        localizationId: String, whatsNew: String?, description: String?,
        keywords: String?, marketingUrl: String?, supportUrl: String?, promotionalText: String?
    ) async throws {
        try await Task.sleep(for: .seconds(1))
    }
}
