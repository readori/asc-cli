import Foundation
import Mockable

@Mockable
public protocol ScreenshotGenerationRepository: Sendable {
    /// For each screen in the plan, calls an AI image generation API with the screen's
    /// `imagePrompt` + the matched screenshot, and returns the generated PNG data
    /// keyed by screen index.
    func generateImages(plan: ScreenPlan, screenshotURLs: [URL]) async throws -> [Int: Data]
}
