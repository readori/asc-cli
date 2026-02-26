import SwiftUI

/// Maps theme mode IDs to theme implementations.
enum ThemeRegistry {
    static let all: [any AppThemeProvider] = [DarkTheme(), LightTheme()]

    static func theme(for id: String) -> any AppThemeProvider {
        all.first { $0.id == id } ?? DarkTheme()
    }
}
