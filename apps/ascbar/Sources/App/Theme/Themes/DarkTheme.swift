import SwiftUI

/// Dark theme — default. Deep navy/indigo gradient with vibrant accents.
public struct DarkTheme: AppThemeProvider {
    public var id: String { "dark" }
    public var displayName: String { "Dark" }
    public var icon: String { "moon.fill" }

    public var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.07, blue: 0.14),
                Color(red: 0.10, green: 0.08, blue: 0.18),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var showBackgroundOrbs: Bool { true }

    public var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.07),
                Color.white.opacity(0.03),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var glassBackground: Color  { Color.white.opacity(0.06) }
    public var glassBorder: Color      { Color.white.opacity(0.10) }
    public var glassHighlight: Color   { Color.white.opacity(0.15) }
    public var cardCornerRadius: CGFloat  { 12 }
    public var pillCornerRadius: CGFloat  { 8 }

    public var textPrimary: Color    { .white }
    public var textSecondary: Color  { Color.white.opacity(0.65) }
    public var textTertiary: Color   { Color.white.opacity(0.40) }
    public var fontDesign: Font.Design { .default }

    public var statusLive: Color       { BaseColors.green }
    public var statusEditable: Color   { BaseColors.amber }
    public var statusPending: Color    { BaseColors.blue }
    public var statusRemoved: Color    { BaseColors.red }
    public var statusProcessing: Color { BaseColors.gray }

    public var accentPrimary: Color    { BaseColors.teal }
    public var accentSecondary: Color  { BaseColors.coral }

    public var accentGradient: LinearGradient {
        LinearGradient(
            colors: [BaseColors.teal, BaseColors.purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    public var pillGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public var hoverOverlay: Color  { Color.white.opacity(0.06) }
    public var progressTrack: Color { Color.white.opacity(0.10) }
}
