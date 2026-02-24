import Foundation
import Mockable

@Mockable
public protocol ScreenshotRepository: Sendable {
    /// List screenshot sets for a specific localization.
    func listScreenshotSets(localizationId: String) async throws -> [AppScreenshotSet]

    func listScreenshots(setId: String) async throws -> [AppScreenshot]

    func createScreenshotSet(localizationId: String, displayType: ScreenshotDisplayType) async throws -> AppScreenshotSet
    func uploadScreenshot(setId: String, fileURL: URL) async throws -> AppScreenshot
}
