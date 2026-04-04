import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppShotsTranslateTests {

    /// Minimal PNG header + padding so data.count > 100
    private static let fakePNG: Data = {
        var bytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        bytes += [UInt8](repeating: 0, count: 200)
        return Data(bytes)
    }()

    private func makePlan(screens: [ScreenDesign] = []) -> ScreenshotDesign {
        ScreenshotDesign(
            appId: "app-1",
            appName: "TestApp",
            tagline: "Your best app",
            tone: .professional,
            colors: ScreenColors(primary: "#000000", accent: "#FF0000", text: "#FFFFFF", subtext: "#CCCCCC"),
            screens: screens
        )
    }

    private func makeScreen(index: Int = 0) -> ScreenDesign {
        ScreenDesign(
            index: index,
            screenshotFile: "screen\(index).png",
            heading: "Great Feature",
            subheading: "Makes life easier",
            layoutMode: .center,
            visualDirection: "Dark background",
            imagePrompt: "Modern app showcase"
        )
    }

    /// Writes a plan to a temp file and returns the path.
    private func writePlanFile(_ plan: ScreenshotDesign) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(plan)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-plan-\(UUID().uuidString).json")
        try data.write(to: url)
        return url.path
    }

    /// Creates a temp source directory with `count` fake screen-N.png files.
    private func makeSourceDir(count: Int) throws -> String {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("app-shots-src-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for i in 0..<count {
            let file = dir.appendingPathComponent("screen-\(i).png")
            try Self.fakePNG.write(to: file)
        }
        return dir.path
    }

    private func makeTempDir() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("app-shots-out-\(UUID().uuidString)").path
    }

    // MARK: - Tests

    @Test func `translate zh writes locale output dir and returns result`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0), makeScreen(index: 1)])
        let planPath = try writePlanFile(plan)
        let sourceDir = try makeSourceDir(count: 2)
        let outputBase = makeTempDir()

        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any)
            .willReturn([0: Self.fakePNG, 1: Self.fakePNG])

        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath,
            "--to", "zh",
            "--source-dir", sourceDir,
            "--output-dir", outputBase
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("zh"))
        #expect(FileManager.default.fileExists(atPath: "\(outputBase)/zh/screen-0.png"))
        #expect(FileManager.default.fileExists(atPath: "\(outputBase)/zh/screen-1.png"))

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: sourceDir)
        try? FileManager.default.removeItem(atPath: outputBase)
    }

    @Test func `translate multiple locales processes all in parallel`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let planPath = try writePlanFile(plan)
        let sourceDir = try makeSourceDir(count: 1)
        let outputBase = makeTempDir()

        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any)
            .willReturn([0: Self.fakePNG])
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any)
            .willReturn([0: Self.fakePNG])

        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath,
            "--to", "zh",
            "--to", "ja",
            "--source-dir", sourceDir,
            "--output-dir", outputBase
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("zh"))
        #expect(output.contains("ja"))
        #expect(FileManager.default.fileExists(atPath: "\(outputBase)/zh/screen-0.png"))
        #expect(FileManager.default.fileExists(atPath: "\(outputBase)/ja/screen-0.png"))

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: sourceDir)
        try? FileManager.default.removeItem(atPath: outputBase)
    }

    @Test func `translate replaces imagePrompt with text-only instruction and drops original design spec`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let planPath = try writePlanFile(plan)
        let sourceDir = try makeSourceDir(count: 1)
        let outputBase = makeTempDir()

        var capturedPlan: ScreenshotDesign?
        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any).willProduce { capturedPlanArg, _, _ in
            capturedPlan = capturedPlanArg
            return [0: Self.fakePNG]
        }

        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath,
            "--to", "zh",
            "--source-dir", sourceDir,
            "--output-dir", outputBase
        ])
        _ = try await cmd.execute(repo: mockRepo)

        let prompt = capturedPlan?.screens[0].imagePrompt ?? ""
        // New prompt asks for text-only translation
        #expect(prompt.contains("ONLY translate"))
        #expect(prompt.contains("zh"))
        // Original imagePrompt must NOT be forwarded — it contains design specs that
        // cause Gemini to regenerate the background/colors instead of just editing text
        #expect(!prompt.contains("Modern app showcase"))
        // Plan tagline/appDescription must be cleared so buildAppContext returns ""
        #expect(capturedPlan?.tagline == "")
        #expect(capturedPlan?.appDescription == nil)

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: sourceDir)
        try? FileManager.default.removeItem(atPath: outputBase)
    }

    @Test func `translate includes heading and subheading in instruction and guards device UI`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let planPath = try writePlanFile(plan)
        let sourceDir = try makeSourceDir(count: 1)
        let outputBase = makeTempDir()

        var capturedPlan: ScreenshotDesign?
        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any).willProduce { p, _, _ in
            capturedPlan = p
            return [0: Self.fakePNG]
        }

        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath,
            "--to", "ja",
            "--source-dir", sourceDir,
            "--output-dir", outputBase
        ])
        _ = try await cmd.execute(repo: mockRepo)

        let prompt = capturedPlan?.screens[0].imagePrompt ?? ""
        #expect(prompt.contains("Great Feature"))
        #expect(prompt.contains("Makes life easier"))
        // Must NOT instruct Gemini to change text inside the device mockup
        #expect(prompt.contains("Do NOT change any text inside the device mockup"))

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: sourceDir)
        try? FileManager.default.removeItem(atPath: outputBase)
    }

    @Test func `translate omits subheading line from prompt when subheading is empty`() async throws {
        let emptySubheadingScreen = ScreenDesign(
            index: 0,
            screenshotFile: "screen0.png",
            heading: "Great Feature",
            subheading: "",
            layoutMode: .center,
            visualDirection: "Dark background",
            imagePrompt: "Some design spec"
        )
        let plan = makePlan(screens: [emptySubheadingScreen])
        let planPath = try writePlanFile(plan)
        let sourceDir = try makeSourceDir(count: 1)
        let outputBase = makeTempDir()
        defer {
            try? FileManager.default.removeItem(atPath: planPath)
            try? FileManager.default.removeItem(atPath: sourceDir)
            try? FileManager.default.removeItem(atPath: outputBase)
        }

        var capturedPlan: ScreenshotDesign?
        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any).willProduce { p, _, _ in
            capturedPlan = p
            return [0: Self.fakePNG]
        }

        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath, "--to", "ko", "--source-dir", sourceDir, "--output-dir", outputBase
        ])
        _ = try await cmd.execute(repo: mockRepo)

        let prompt = capturedPlan?.screens[0].imagePrompt ?? ""
        #expect(prompt.contains("Heading: \"Great Feature\""))
        #expect(!prompt.contains("Subheading"))
    }

    @Test func `translate throws when no existing screenshots found`() async throws {
        let plan = makePlan(screens: [makeScreen()])
        let planPath = try writePlanFile(plan)
        let emptySourceDir = makeTempDir()
        try FileManager.default.createDirectory(atPath: emptySourceDir, withIntermediateDirectories: true)

        let mockRepo = MockScreenshotGenerationRepository()
        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath,
            "--to", "zh",
            "--source-dir", emptySourceDir,
            "--output-dir", makeTempDir()
        ])

        do {
            _ = try await cmd.execute(repo: mockRepo)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error.localizedDescription.contains("generate") || String(describing: error).contains("generate"))
        }

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: emptySourceDir)
    }

    @Test func `translate throws when no --to locales specified`() async throws {
        let plan = makePlan(screens: [makeScreen()])
        let planPath = try writePlanFile(plan)
        let sourceDir = try makeSourceDir(count: 1)

        let mockRepo = MockScreenshotGenerationRepository()
        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath,
            "--source-dir", sourceDir,
            "--output-dir", makeTempDir()
        ])

        do {
            _ = try await cmd.execute(repo: mockRepo)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(true)
        }

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: sourceDir)
    }

    @Test func `translate json output contains locale and screens count`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let planPath = try writePlanFile(plan)
        let sourceDir = try makeSourceDir(count: 1)
        let outputBase = makeTempDir()

        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any)
            .willReturn([0: Self.fakePNG])

        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath,
            "--to", "ko",
            "--source-dir", sourceDir,
            "--output-dir", outputBase
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("\"locale\":\"ko\""))
        #expect(output.contains("\"screens\":1"))

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: sourceDir)
        try? FileManager.default.removeItem(atPath: outputBase)
    }

    @Test func `--device-type APP_IPHONE_67 overrides default output dimensions`() async throws {
        let cmd = try AppShotsTranslate.parse(["--device-type", "APP_IPHONE_67", "--to", "zh"])
        #expect(cmd.deviceType == .iphone67)
        #expect(cmd.deviceType?.dimensions.width == 1290)
        #expect(cmd.deviceType?.dimensions.height == 2796)
    }

    @Test func `--device-type APP_IPAD_PRO_129 overrides default output dimensions`() async throws {
        let cmd = try AppShotsTranslate.parse(["--device-type", "APP_IPAD_PRO_129", "--to", "ja"])
        #expect(cmd.deviceType == .ipadPro129)
        #expect(cmd.deviceType?.dimensions.width == 2048)
        #expect(cmd.deviceType?.dimensions.height == 2732)
    }

    @Test func `--style-reference passes reference URL to repository during translation`() async throws {
        let refFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("ref-\(UUID().uuidString).png")
        try Self.fakePNG.write(to: refFile)
        defer { try? FileManager.default.removeItem(at: refFile) }

        let plan = makePlan(screens: [makeScreen(index: 0)])
        let planPath = try writePlanFile(plan)
        let sourceDir = try makeSourceDir(count: 1)
        let outputBase = makeTempDir()
        defer {
            try? FileManager.default.removeItem(atPath: planPath)
            try? FileManager.default.removeItem(atPath: sourceDir)
            try? FileManager.default.removeItem(atPath: outputBase)
        }

        var capturedStyleRef: URL?
        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any).willProduce { _, _, styleRef in
            capturedStyleRef = styleRef
            return [0: Self.fakePNG]
        }

        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath,
            "--to", "zh",
            "--source-dir", sourceDir,
            "--output-dir", outputBase,
            "--style-reference", refFile.path
        ])
        _ = try await cmd.execute(repo: mockRepo)

        #expect(capturedStyleRef == refFile)
    }

    @Test func `translate table output contains locale column header`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let planPath = try writePlanFile(plan)
        let sourceDir = try makeSourceDir(count: 1)
        let outputBase = makeTempDir()

        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any, styleReferenceURL: .any)
            .willReturn([0: Self.fakePNG])

        let cmd = try AppShotsTranslate.parse([
            "--plan", planPath,
            "--to", "zh",
            "--source-dir", sourceDir,
            "--output-dir", outputBase,
            "--output", "table"
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("| Locale | Screens | Output Dir |"))
        #expect(output.contains("zh"))

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: sourceDir)
        try? FileManager.default.removeItem(atPath: outputBase)
    }
}
