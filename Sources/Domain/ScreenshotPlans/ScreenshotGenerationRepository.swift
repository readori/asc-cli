import Foundation
import Mockable

@Mockable
public protocol ScreenshotGenerationRepository: Sendable {
    /// For each screen in the plan, calls an AI image generation API with the screen's
    /// `imagePrompt` + the matched screenshot, and returns the generated PNG data
    /// keyed by screen index.
    ///
    /// - Parameters:
    ///   - plan: The ScreenPlan describing all screens, colors, and tone.
    ///   - screenshotURLs: Source app screenshots — matched by filename then index order.
    ///   - styleReferenceURL: Optional reference image whose visual style (colors, typography,
    ///     layout patterns) Gemini should replicate. Content is not copied — only the aesthetic.
    func generateImages(plan: ScreenPlan, screenshotURLs: [URL], styleReferenceURL: URL?) async throws -> [Int: Data]
}
