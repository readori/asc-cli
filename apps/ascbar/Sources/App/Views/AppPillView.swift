import SwiftUI
import Domain

/// A tappable pill for selecting an app in the app switcher row.
struct AppPillView: View {
    let app: ASCApp
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            Text(app.displayName)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular, design: theme.fontDesign))
                .foregroundStyle(isSelected ? theme.accentPrimary : theme.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                        .fill(isSelected ? theme.accentPrimary.opacity(0.15) : (isHovering ? theme.hoverOverlay : Color.clear))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.pillCornerRadius)
                                .strokeBorder(
                                    isSelected ? theme.accentPrimary.opacity(0.4) : theme.glassBorder,
                                    lineWidth: 1
                                )
                        )
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
