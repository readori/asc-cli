import SwiftUI

// MARK: - Environment Key

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: any AppThemeProvider = DarkTheme()
}

extension EnvironmentValues {
    var appTheme: any AppThemeProvider {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - View Modifier

struct AppThemeModifier: ViewModifier {
    let themeModeId: String

    func body(content: Content) -> some View {
        content.environment(\.appTheme, ThemeRegistry.theme(for: themeModeId))
    }
}

extension View {
    func appThemeProvider(themeModeId: String) -> some View {
        modifier(AppThemeModifier(themeModeId: themeModeId))
    }
}
