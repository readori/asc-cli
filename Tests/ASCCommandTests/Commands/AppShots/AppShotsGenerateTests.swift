import Foundation
import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppShotsGenerateTests {

    /// Minimal PNG header + padding so data.count > 100
    private static let fakePNG: Data = {
        var bytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        bytes += [UInt8](repeating: 0, count: 200)
        return Data(bytes)
    }()

    private func makePlan(
        appId: String = "app-1",
        screens: [ScreenConfig] = []
    ) -> ScreenPlan {
        ScreenPlan(
            appId: appId,
            appName: "TestApp",
            tagline: "Your best app",
            tone: .professional,
            colors: ScreenColors(primary: "#000000", accent: "#FF0000", text: "#FFFFFF", subtext: "#CCCCCC"),
            screens: screens
        )
    }

    private func makeScreen(index: Int = 0) -> ScreenConfig {
        ScreenConfig(
            index: index,
            screenshotFile: "screen\(index).png",
            heading: "Great Feature",
            subheading: "Makes life easier",
            layoutMode: .center,
            visualDirection: "Dark background",
            imagePrompt: "Modern app showcase with dark navy background"
        )
    }

    private func writePlanFile(_ plan: ScreenPlan) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(plan)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-plan-\(UUID().uuidString).json")
        try data.write(to: url)
        return url.path
    }

    private func makeTempOutputDir() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("app-shots-test-\(UUID().uuidString)").path
    }

    @Test func `generate saves PNG for each screen and reports paths`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let planPath = try writePlanFile(plan)
        let outputDir = makeTempOutputDir()

        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any)
            .willReturn([0: Self.fakePNG])

        let cmd = try AppShotsGenerate.parse(["--plan", planPath, "--output-dir", outputDir])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("screen-0.png"))
        #expect(FileManager.default.fileExists(atPath: "\(outputDir)/screen-0.png"))

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: outputDir)
    }

    @Test func `generate saves multiple screens with correct indices`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0), makeScreen(index: 1)])
        let planPath = try writePlanFile(plan)
        let outputDir = makeTempOutputDir()

        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any)
            .willReturn([0: Self.fakePNG, 1: Self.fakePNG])

        let cmd = try AppShotsGenerate.parse(["--plan", planPath, "--output-dir", outputDir])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("screen-0.png"))
        #expect(output.contains("screen-1.png"))
        #expect(FileManager.default.fileExists(atPath: "\(outputDir)/screen-0.png"))
        #expect(FileManager.default.fileExists(atPath: "\(outputDir)/screen-1.png"))

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: outputDir)
    }

    @Test func `generate creates output directory if it does not exist`() async throws {
        let plan = makePlan(screens: [makeScreen()])
        let planPath = try writePlanFile(plan)
        let outputDir = makeTempOutputDir() + "/nested/dir"

        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any)
            .willReturn([0: Self.fakePNG])

        let cmd = try AppShotsGenerate.parse(["--plan", planPath, "--output-dir", outputDir])
        _ = try await cmd.execute(repo: mockRepo)

        #expect(FileManager.default.fileExists(atPath: outputDir))

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: outputDir)
    }

    @Test func `generate table output contains screen index`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let planPath = try writePlanFile(plan)
        let outputDir = makeTempOutputDir()

        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any)
            .willReturn([0: Self.fakePNG])

        let cmd = try AppShotsGenerate.parse(["--plan", planPath, "--output-dir", outputDir, "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("| Screen | File |"))
        #expect(output.contains("screen-0.png"))

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: outputDir)
    }

    @Test func `generate throws when plan file not found`() async throws {
        let mockRepo = MockScreenshotGenerationRepository()
        let cmd = try AppShotsGenerate.parse(["--plan", "/nonexistent/plan.json"])
        do {
            _ = try await cmd.execute(repo: mockRepo)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(true)
        }
    }

    @Test func `generate auto-discovers screenshots from plan directory when none provided`() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("app-shots-autodiscover-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let plan = makePlan(screens: [makeScreen(index: 0), makeScreen(index: 1)])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let planData = try encoder.encode(plan)
        let planURL = tmpDir.appendingPathComponent("app-shots-plan.json")
        try planData.write(to: planURL)

        // Place two fake PNGs in the same directory
        try Self.fakePNG.write(to: tmpDir.appendingPathComponent("screen1.png"))
        try Self.fakePNG.write(to: tmpDir.appendingPathComponent("screen2.png"))

        let outputDir = tmpDir.appendingPathComponent("output").path
        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any)
            .willReturn([0: Self.fakePNG, 1: Self.fakePNG])

        // No screenshots argument — auto-discovery should find screen1.png and screen2.png
        let cmd = try AppShotsGenerate.parse(["--plan", planURL.path, "--output-dir", outputDir])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("screen-0.png"))
        #expect(output.contains("screen-1.png"))
    }

    @Test func `--device-type APP_IPHONE_67 overrides default output dimensions`() async throws {
        let plan = makePlan(screens: [makeScreen()])
        let planPath = try writePlanFile(plan)
        let outputDir = makeTempOutputDir()

        let mockRepo = MockScreenshotGenerationRepository()
        given(mockRepo).generateImages(plan: .any, screenshotURLs: .any)
            .willReturn([0: Self.fakePNG])

        let cmd = try AppShotsGenerate.parse([
            "--plan", planPath,
            "--output-dir", outputDir,
            "--device-type", "APP_IPHONE_67"
        ])
        #expect(cmd.deviceType == .iphone67)
        #expect(cmd.deviceType?.dimensions.width == 1290)
        #expect(cmd.deviceType?.dimensions.height == 2796)

        try? FileManager.default.removeItem(atPath: planPath)
        try? FileManager.default.removeItem(atPath: outputDir)
    }

    @Test func `--device-type APP_IPAD_PRO_129 overrides default output dimensions`() async throws {
        let cmd = try AppShotsGenerate.parse(["--device-type", "APP_IPAD_PRO_129"])
        #expect(cmd.deviceType == .ipadPro129)
        #expect(cmd.deviceType?.dimensions.width == 2048)
        #expect(cmd.deviceType?.dimensions.height == 2732)
    }

    @Test func `generate throws when screenshot file not found`() async throws {
        let plan = makePlan()
        let planPath = try writePlanFile(plan)
        let mockRepo = MockScreenshotGenerationRepository()

        let cmd = try AppShotsGenerate.parse([
            "--plan", planPath,
            "/nonexistent/screen.png"
        ])
        do {
            _ = try await cmd.execute(repo: mockRepo)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(true)
        }

        try? FileManager.default.removeItem(atPath: planPath)
    }
}
