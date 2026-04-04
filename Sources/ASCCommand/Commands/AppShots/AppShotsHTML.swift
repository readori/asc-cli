import ArgumentParser
import Domain
import Foundation

struct AppShotsHTML: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "html",
        abstract: "Generate a self-contained HTML page for App Store screenshots — no AI needed"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Path to plan.json (default: .asc/app-shots/app-shots-plan.json)")
    var plan: String = ".asc/app-shots/app-shots-plan.json"

    @Option(name: .long, help: "Directory to write the HTML file (default: .asc/app-shots/output)")
    var outputDir: String = ".asc/app-shots/output"

    @Option(name: .long, help: "Output image width in pixels (default: 1320 — iPhone 6.9\")")
    var outputWidth: Int = 1320

    @Option(name: .long, help: "Output image height in pixels (default: 2868 — iPhone 6.9\")")
    var outputHeight: Int = 2868

    @Option(name: .long, help: "Named device type — overrides --output-width/height")
    var deviceType: AppShotsDisplayType?

    @Option(name: .long, help: "Device mockup: a file path, a device name from mockups.json, or \"none\" to disable. Default: bundled iPhone 17 Pro Max frame.")
    var mockup: String?

    @Option(name: .long, help: "Screen area X inset in pixels from mockup edge (overrides mockups.json value)")
    var screenInsetX: Int?

    @Option(name: .long, help: "Screen area Y inset in pixels from mockup edge (overrides mockups.json value)")
    var screenInsetY: Int?

    @Argument(help: "Screenshot files — omit to auto-discover *.png/*.jpg from the plan's directory")
    var screenshots: [String] = []

    func run() async throws {
        print(try await execute())
    }

    func execute() async throws -> String {
        let planURL = URL(fileURLWithPath: plan)
        let planData = try Data(contentsOf: planURL)
        let planDir = planURL.deletingLastPathComponent()

        // Try CompositionPlan first (has "canvas" key), fallback to ScreenshotDesign
        if let compositionPlan = try? JSONDecoder().decode(CompositionPlan.self, from: planData) {
            return try executeComposition(compositionPlan, planDir: planDir)
        }

        let loadedPlan = try JSONDecoder().decode(ScreenshotDesign.self, from: planData)
        return try executeLegacy(loadedPlan, planDir: planDir)
    }

    // MARK: - Composition Plan path

    private func executeComposition(_ plan: CompositionPlan, planDir: URL) throws -> String {
        let screenshotDataURIs = loadScreenshotDataURIs(planDir: planDir)

        // Resolve mockup for each unique device name
        var mockupCache: [String: MockupInfo] = [:]
        let deviceNames = Set(plan.screens.flatMap { $0.devices.map(\.mockup) })
        for name in deviceNames {
            if let info = try resolveMockupInfoForDevice(name: name) {
                mockupCache[name] = info
            }
        }

        let assets = RenderAssets(screenshotDataURIs: screenshotDataURIs, mockups: mockupCache)
        let html = CompositionHTMLRenderer.render(plan: plan, assets: assets)
        return try writeHTML(html)
    }

    // MARK: - Legacy ScreenshotDesign path

    private func executeLegacy(_ loadedPlan: ScreenshotDesign, planDir: URL) throws -> String {
        let effectiveWidth = deviceType.map { $0.dimensions.width } ?? outputWidth
        let effectiveHeight = deviceType.map { $0.dimensions.height } ?? outputHeight

        let screenshotDataURIs = loadScreenshotDataURIs(planDir: planDir, validateExists: true)

        var mockups: [String: MockupInfo] = [:]
        if let info = try resolveLegacyMockupInfo() {
            mockups["__default__"] = info
        }

        let assets = RenderAssets(screenshotDataURIs: screenshotDataURIs, mockups: mockups)
        let html = LegacyHTMLRenderer.render(plan: loadedPlan, assets: assets, width: effectiveWidth, height: effectiveHeight)
        return try writeHTML(html)
    }

    // MARK: - Shared helpers

    private func loadScreenshotDataURIs(planDir: URL, validateExists: Bool = false) -> [String: String] {
        let searchPaths: [String]
        if screenshots.isEmpty {
            let contents = (try? FileManager.default.contentsOfDirectory(at: planDir, includingPropertiesForKeys: nil)) ?? []
            searchPaths = contents
                .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
                .map { $0.path }
        } else {
            searchPaths = screenshots
        }

        var dataURIs: [String: String] = [:]
        for path in searchPaths {
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            guard let data = try? Data(contentsOf: url) else { continue }
            let ext = url.pathExtension.lowercased()
            let mime = ext == "jpg" || ext == "jpeg" ? "image/jpeg" : "image/png"
            dataURIs[url.lastPathComponent] = "data:\(mime);base64,\(data.base64EncodedString())"
        }
        return dataURIs
    }

    private func resolveMockupInfoForDevice(name: String) throws -> MockupInfo? {
        guard let r = try MockupResolver.resolve(argument: name, insetXOverride: nil, insetYOverride: nil) else {
            return nil
        }
        let data = try Data(contentsOf: r.fileURL)
        return MockupInfo(
            dataURI: "data:image/png;base64,\(data.base64EncodedString())",
            frameWidth: r.frameWidth,
            frameHeight: r.frameHeight,
            insetX: r.screenInsetX,
            insetY: r.screenInsetY
        )
    }

    private func resolveLegacyMockupInfo() throws -> MockupInfo? {
        guard let r = try MockupResolver.resolve(
            argument: mockup,
            insetXOverride: screenInsetX,
            insetYOverride: screenInsetY
        ) else { return nil }

        let data = try Data(contentsOf: r.fileURL)
        return MockupInfo(
            dataURI: "data:image/png;base64,\(data.base64EncodedString())",
            frameWidth: r.frameWidth,
            frameHeight: r.frameHeight,
            insetX: r.screenInsetX,
            insetY: r.screenInsetY
        )
    }

    private func writeHTML(_ html: String) throws -> String {
        let outputDirURL = URL(fileURLWithPath: outputDir)
        try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true)
        let htmlPath = outputDirURL.appendingPathComponent("app-shots.html")
        try html.write(to: htmlPath, atomically: true, encoding: .utf8)
        return formatOutput(path: htmlPath.path)
    }

    private func formatOutput(path: String) -> String {
        switch globals.outputFormat {
        case .table:
            return "| File |\n|------|\n| \(path) |"
        case .markdown:
            return "## Generated HTML\n\n- `\(path)`"
        default:
            return "{\"file\":\"\(path)\"}"
        }
    }
}
