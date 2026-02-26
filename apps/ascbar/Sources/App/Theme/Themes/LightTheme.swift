import SwiftUI

/// Light theme — clean white/grey with coloured accents.
public struct LightTheme: AppThemeProvider {
    public var id: String { "light" }
    public var displayName: String { "Light" }
    public var icon: String { "sun.max.fill" }

    public var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.96, blue: 0.98),
                Color(red: 0.92, green: 0.92, blue: 0.97),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var showBackgroundOrbs: Bool { false }

    public var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.90), Color.white.opacity(0.70)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public var glassBackground: Color  { Color.white.opacity(0.80) }
    public var glassBorder: Color      { Color.black.opacity(0.08) }
    public var glassHighlight: Color   { Color.white }
    public var cardCornerRadius: CGFloat  { 12 }
    public var pillCornerRadius: CGFloat  { 8 }

    public var textPrimary: Color    { Color(red: 0.10, green: 0.10, blue: 0.12) }
    public var textSecondary: Color  { Color(red: 0.35, green: 0.35, blue: 0.40) }
    public var textTertiary: Color   { Color(red: 0.60, green: 0.60, blue: 0.65) }
    public var fontDesign: Font.Design { .default }

    public var statusLive: Color       { Color(red: 0.18, green: 0.72, blue: 0.44) }
    public var statusEditable: Color   { Color(red: 0.85, green: 0.60, blue: 0.10) }
    public var statusPending: Color    { Color(red: 0.20, green: 0.45, blue: 0.90) }
    public var statusRemoved: Color    { Color(red: 0.85, green: 0.25, blue: 0.30) }
    public var statusProcessing: Color { Color(red: 0.50, green: 0.50, blue: 0.55) }

    public var accentPrimary: Color    { Color(red: 0.20, green: 0.55, blue: 0.95) }
    public var accentSecondary: Color  { Color(red: 0.45, green: 0.22, blue: 0.85) }

    public var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentPrimary, accentSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    public var pillGradient: LinearGradient {
        LinearGradient(
            colors: [Color.black.opacity(0.06), Color.black.opacity(0.03)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public var hoverOverlay: Color  { Color.black.opacity(0.04) }
    public var progressTrack: Color { Color.black.opacity(0.08) }
}
