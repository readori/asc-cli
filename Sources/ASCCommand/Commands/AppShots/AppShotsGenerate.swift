import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AppShotsGenerate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Enhance App Store screenshots using Gemini AI"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Screenshot file to enhance")
    var file: String

    @Option(name: .long, help: "Gemini API key (falls back to GEMINI_API_KEY env var)")
    var geminiApiKey: String?

    @Option(name: .long, help: "Gemini image generation model")
    var model: String = "gemini-2.0-flash-exp"

    @Option(name: .long, help: "Output directory (default: .asc/app-shots/output)")
    var outputDir: String = ".asc/app-shots/output"

    @Option(name: .long, help: "Output width in pixels")
    var outputWidth: Int = 1320

    @Option(name: .long, help: "Output height in pixels")
    var outputHeight: Int = 2868

    @Option(name: .long, help: "Named device type — overrides width/height")
    var deviceType: AppShotsDisplayType?

    @Option(name: .long, help: "Style reference image — Gemini replicates its visual style")
    var styleReference: String?

    @Option(name: .long, help: "Custom enhancement prompt — describe what to change")
    var prompt: String?

    func run() async throws {
        let configStorage = FileAppShotsConfigStorage()
        let apiKey = try resolveGeminiApiKey(geminiApiKey, configStorage: configStorage)
        let repo = ClientProvider.makeScreenshotGenerationRepository(apiKey: apiKey, model: model)
        print(try await execute(repo: repo))
    }

    func execute(repo: any ScreenshotGenerationRepository) async throws -> String {
        let effectiveWidth = deviceType.map { $0.dimensions.width } ?? outputWidth
        let effectiveHeight = deviceType.map { $0.dimensions.height } ?? outputHeight

        // Validate input file
        let fileURL = URL(fileURLWithPath: file)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ValidationError("File not found: \(file)")
        }

        // Style reference
        let styleRefURL: URL? = try {
            guard let path = styleReference, !path.isEmpty else { return nil }
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ValidationError("Style reference not found: \(path)")
            }
            return url
        }()

        // Build the enhancement prompt
        let enhancePrompt = buildPrompt(hasStyleRef: styleRefURL != nil)

        // Build a minimal ScreenshotDesign for the repository
        let design = ScreenshotDesign(
            appId: "", appName: "App",
            tagline: enhancePrompt,
            tone: .professional,
            colors: ScreenColors(primary: "#000000", accent: "#4A90E2", text: "#FFFFFF", subtext: "#94A3B8"),
            screens: [
                ScreenDesign(
                    index: 0, screenshotFile: file,
                    heading: "", subheading: "",
                    layoutMode: .center, visualDirection: "",
                    imagePrompt: enhancePrompt
                )
            ]
        )

        // Create output directory
        let outputDirURL = URL(fileURLWithPath: outputDir)
        try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true)

        // Generate
        let images = try await repo.generateImages(
            plan: design, screenshotURLs: [fileURL], styleReferenceURL: styleRefURL
        )

        // Write output
        var entries: [(index: Int, path: String)] = []
        for (index, data) in images.sorted(by: { $0.key < $1.key }) {
            let fileName = "screen-\(index).png"
            let fileURL = outputDirURL.appendingPathComponent(fileName)
            let resized = resizeImageData(data, toWidth: effectiveWidth, height: effectiveHeight)
            try resized.write(to: fileURL)
            entries.append((index: index, path: fileURL.path))
        }

        return formatOutput(entries: entries)
    }

    // MARK: - Prompt

    private func buildPrompt(hasStyleRef: Bool) -> String {
        // Custom prompt takes priority
        if let custom = prompt, !custom.isEmpty {
            return custom
        }

        // Style transfer mode
        if hasStyleRef {
            return """
            You are enhancing an App Store screenshot to match the visual style of a reference image.

            STYLE REFERENCE (first image):
            Match its visual style EXACTLY: same device frame rendering, same text treatment, same background style, same level of polish. This defines HOW the screenshot should look.

            SCREENSHOT (second image):
            This is the composed screenshot to enhance. Keep its layout, text, and content.

            REQUIREMENTS:
            - The device frame MUST be a photorealistic iPhone mockup — sleek, with accurate proportions, reflections, and subtle shadows
            - Match the reference's background treatment, text rendering, and overall aesthetic
            - Keep the screenshot's content and layout unchanged
            - Professional, high-budget App Store quality
            - No watermarks, no extra text, no app store UI chrome
            """
        }

        // Default: auto-enhance
        return """
        Transform this composed App Store screenshot into a polished, professional marketing image that makes someone tap Download.

        KEEP EXACTLY AS-IS:
        - All text (wording, position, approximate size)
        - The app screenshot content shown on the device
        - The overall layout and composition

        ENHANCE AND POLISH:
        - Replace any flat device frame with a photorealistic iPhone 15 Pro mockup — sleek, modern, with accurate proportions, subtle reflections and shadows. The phone should look like a real device.
        - If there is an obvious, compelling UI panel on the app screen, make it "break out" from the device frame — scale it up so it extends beyond both left and right edges of the phone, overlapping the bezel. Add a soft drop shadow beneath for depth. Only do this if a panel clearly reinforces the message. A clean screenshot with no breakout is better than a forced one.
        - Optionally add 1-2 small supporting elements (contextual icons, subtle badges) that reinforce the message — but only if they add value. Less is more.
        - Ensure text is crisp, bold, and highly readable
        - The background should be clean and bold — no glows, gradients, radial patterns, or noise

        The result should look like it was designed by a professional App Store screenshot agency — polished, high-converting, visually striking. No watermarks, no extra text, no app store UI chrome.
        """
    }

    // MARK: - Output

    private func formatOutput(entries: [(index: Int, path: String)]) -> String {
        switch globals.outputFormat {
        case .table:
            var lines = ["| Screen | File |", "|--------|------|"]
            for entry in entries {
                lines.append("| \(entry.index)      | \(entry.path) |")
            }
            return lines.joined(separator: "\n")
        case .markdown:
            var lines = ["## Generated Screenshots", ""]
            for entry in entries {
                lines.append("- Screen \(entry.index): `\(entry.path)`")
            }
            return lines.joined(separator: "\n")
        default:
            let objects = entries.map { "{\"screenIndex\":\($0.index),\"file\":\"\($0.path)\"}" }
            let body = objects.joined(separator: globals.pretty ? ",\n  " : ",")
            if globals.pretty {
                return "{\n  \"generated\" : [\n  \(body)\n  ]\n}"
            } else {
                return "{\"generated\":[\(body)]}"
            }
        }
    }
}
