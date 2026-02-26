import SwiftUI
import Domain

/// Displays a single app version with its platform, version string, state badge, and quick actions.
struct VersionCardView: View {
    let version: ASCVersion

    @Environment(\.appTheme) private var theme
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Platform badge
            Text(version.platformDisplayName)
                .font(.system(size: 10, weight: .medium, design: theme.fontDesign))
                .foregroundStyle(theme.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.glassBackground)
                        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(theme.glassBorder, lineWidth: 0.5))
                )

            // Version string
            Text(version.versionString)
                .font(.system(size: 13, weight: .semibold, design: theme.fontDesign))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            // State badge
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(version.stateDisplayName)
                    .font(.system(size: 11, weight: .medium, design: theme.fontDesign))
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(statusColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(statusColor.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                        .strokeBorder(theme.glassBorder, lineWidth: 0.5)
                )
        }
        .onHover { isHovering = $0 }
    }

    private var statusColor: Color {
        theme.statusColor(for: version.appStatus)
    }
}
