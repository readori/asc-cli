import Foundation
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct AppShotsHTMLTests {

    /// Minimal PNG header + padding
    private static let fakePNG: Data = {
        var bytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        bytes += [UInt8](repeating: 0, count: 200)
        return Data(bytes)
    }()

    private func makePlan(
        appName: String = "TestApp",
        screens: [ScreenConfig] = []
    ) -> ScreenPlan {
        ScreenPlan(
            appId: "app-1",
            appName: appName,
            tagline: "Your best app",
            tone: .professional,
            colors: ScreenColors(primary: "#0A1628", accent: "#4A7CFF", text: "#FFFFFF", subtext: "#A8B8D0"),
            screens: screens
        )
    }

    private func makeScreen(
        index: Int = 0,
        heading: String = "Great Feature",
        subheading: String = "Makes life easier",
        layoutMode: LayoutMode = .center
    ) -> ScreenConfig {
        ScreenConfig(
            index: index,
            screenshotFile: "screen\(index).png",
            heading: heading,
            subheading: subheading,
            layoutMode: layoutMode,
            visualDirection: "Dark background",
            imagePrompt: "Modern app showcase"
        )
    }

    private func writePlanAndScreenshots(
        plan: ScreenPlan,
        screenshotCount: Int = 0
    ) throws -> (planPath: String, screenshotPaths: [String]) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("app-shots-html-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let planURL = dir.appendingPathComponent("plan.json")
        try encoder.encode(plan).write(to: planURL)

        var screenshotPaths: [String] = []
        for i in 0..<screenshotCount {
            let path = dir.appendingPathComponent("screen\(i).png")
            try Self.fakePNG.write(to: path)
            screenshotPaths.append(path.path)
        }

        return (planURL.path, screenshotPaths)
    }

    private func makeTempOutputDir() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("app-shots-html-out-\(UUID().uuidString)").path
    }

    // MARK: - Basic HTML generation

    @Test func `html generates an HTML file from the plan`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        let output = try await cmd.execute()

        let htmlPath = "\(outputDir)/app-shots.html"
        #expect(FileManager.default.fileExists(atPath: htmlPath))
        #expect(output.contains("app-shots.html"))
    }

    @Test func `html embeds heading and subheading from plan`() async throws {
        let plan = makePlan(screens: [
            makeScreen(index: 0, heading: "Amazing Feature", subheading: "Works like magic")
        ])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("Amazing Feature"))
        #expect(html.contains("Works like magic"))
    }

    @Test func `html applies plan colors to CSS`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("#0A1628"))  // primary background
        #expect(html.contains("#4A7CFF"))  // accent (category label + buttons)
        #expect(html.contains("#FFFFFF"))  // text (heading)
    }

    @Test func `html embeds screenshots as base64 data URIs`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("data:image/png;base64,"))
    }

    @Test func `html renders multiple screens`() async throws {
        let plan = makePlan(screens: [
            makeScreen(index: 0, heading: "First Screen"),
            makeScreen(index: 1, heading: "Second Screen"),
            makeScreen(index: 2, heading: "Third Screen"),
        ])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 3)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("First Screen"))
        #expect(html.contains("Second Screen"))
        #expect(html.contains("Third Screen"))
    }

    @Test func `html supports different layout modes`() async throws {
        let plan = makePlan(screens: [
            makeScreen(index: 0, layoutMode: .center),
            makeScreen(index: 1, layoutMode: .left),
            makeScreen(index: 2, layoutMode: .tilted),
        ])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 3)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("layout-center"))
        #expect(html.contains("layout-left"))
        #expect(html.contains("layout-tilted"))
    }

    @Test func `html creates output directory if it does not exist`() async throws {
        let plan = makePlan(screens: [makeScreen()])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir() + "/nested/dir"
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        #expect(FileManager.default.fileExists(atPath: outputDir))
    }

    @Test func `html auto-discovers screenshots from plan directory`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, _) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let htmlPath = "\(outputDir)/app-shots.html"
        #expect(FileManager.default.fileExists(atPath: htmlPath))
    }

    @Test func `html includes export functionality`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("html-to-image"))
        #expect(html.contains("Export"))
    }

    @Test func `html includes device dimensions for export`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse([
            "--plan", planPath, "--output-dir", outputDir,
            "--device-type", "APP_IPHONE_67", "--mockup", "none"
        ] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("1290"))
        #expect(html.contains("2796"))
    }

    @Test func `html throws when plan file not found`() async throws {
        let cmd = try AppShotsHTML.parse(["--plan", "/nonexistent/plan.json", "--mockup", "none"])
        do {
            _ = try await cmd.execute()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(true)
        }
    }

    @Test func `html app name appears in the page title`() async throws {
        let plan = makePlan(appName: "SuperApp", screens: [makeScreen()])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("<title>SuperApp"))
    }

    // MARK: - Mockup tests

    @Test func `html with custom mockup path embeds frame and uses screen-content class`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()

        let mockupPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("mockup-\(UUID().uuidString).png")
        try Self.fakePNG.write(to: mockupPath)

        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
            try? FileManager.default.removeItem(at: mockupPath)
        }

        let cmd = try AppShotsHTML.parse([
            "--plan", planPath, "--output-dir", outputDir,
            "--mockup", mockupPath.path,
            "--screen-inset-x", "80", "--screen-inset-y", "70"
        ] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("mockup-frame"))
        #expect(html.contains("screen-content"))
        #expect(html.contains("Device frame"))
    }

    @Test func `html with --mockup none disables mockup frame`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("box-shadow"))
        #expect(!html.contains("mockup-frame"))
    }

    @Test func `html default uses bundled mockup with mockup-frame class`() async throws {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let (planPath, screenshots) = try writePlanAndScreenshots(plan: plan, screenshotCount: 1)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        // No --mockup flag — should use bundled default
        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("mockup-frame"))
        #expect(html.contains("screen-content"))
    }

    @Test func `mockup resolver finds device by name`() throws {
        // This tests that the bundled mockups.json has the expected default entry
        let resolved = try MockupResolver.resolve(argument: nil, insetXOverride: nil, insetYOverride: nil)
        #expect(resolved != nil)
        #expect(resolved?.screenInsetX == 75)
        #expect(resolved?.screenInsetY == 66)
        #expect(resolved?.frameWidth == 1470)
        #expect(resolved?.frameHeight == 3000)
    }

    @Test func `mockup resolver returns nil for --mockup none`() throws {
        let resolved = try MockupResolver.resolve(argument: "none", insetXOverride: nil, insetYOverride: nil)
        #expect(resolved == nil)
    }

    @Test func `mockup resolver applies inset overrides`() throws {
        let resolved = try MockupResolver.resolve(argument: nil, insetXOverride: 100, insetYOverride: 200)
        #expect(resolved != nil)
        #expect(resolved?.screenInsetX == 100)
        #expect(resolved?.screenInsetY == 200)
    }

    // MARK: - CompositionPlan HTML generation

    private func writeCompositionPlanAndScreenshots(
        plan: CompositionPlan,
        screenshotFiles: [String] = []
    ) throws -> (planPath: String, screenshotPaths: [String]) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("app-shots-comp-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let planURL = dir.appendingPathComponent("composition-plan.json")
        try JSONEncoder().encode(plan).write(to: planURL)

        var paths: [String] = []
        for file in screenshotFiles {
            let path = dir.appendingPathComponent(file)
            try Self.fakePNG.write(to: path)
            paths.append(path.path)
        }
        return (planURL.path, paths)
    }

    private func makeCompositionPlan(
        appName: String = "TestApp",
        screens: [SlideComposition] = []
    ) -> CompositionPlan {
        CompositionPlan(
            appName: appName,
            canvas: CanvasSize(width: 1320, height: 2868),
            defaults: SlideDefaults(
                background: .solid("#000000"),
                textColor: "#FFFFFF",
                subtextColor: "#A8B8D0",
                accentColor: "#4A7CFF",
                font: "Inter"
            ),
            screens: screens
        )
    }

    @Test func `composition plan generates HTML with text overlays`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                texts: [
                    TextOverlay(content: "Hero Title", x: 0.065, y: 0.04, fontSize: 0.1, color: "#FFFFFF"),
                    TextOverlay(content: "Subtitle text", x: 0.065, y: 0.09, fontSize: 0.03, color: "#A8B8D0")
                ],
                devices: [
                    DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.85)
                ]
            )
        ])
        let (planPath, screenshots) = try writeCompositionPlanAndScreenshots(plan: plan, screenshotFiles: ["s1.png"])
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("Hero Title"))
        #expect(html.contains("Subtitle text"))
    }

    @Test func `composition plan renders gradient background`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                background: .gradient(from: "#2A1B5E", to: "#000000", angle: 180),
                texts: [TextOverlay(content: "Test", x: 0.065, y: 0.04, fontSize: 0.1, color: "#FFF")],
                devices: []
            )
        ])
        let (planPath, _) = try writeCompositionPlanAndScreenshots(plan: plan)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("#2A1B5E"))
        #expect(html.contains("linear-gradient"))
    }

    @Test func `composition plan renders solid background from defaults`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Test", x: 0.065, y: 0.04, fontSize: 0.1, color: "#FFF")],
                devices: []
            )
        ])
        let (planPath, _) = try writeCompositionPlanAndScreenshots(plan: plan)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("#000000"))
    }

    @Test func `composition plan supports multiple devices per slide`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Dual View", x: 0.5, y: 0.04, fontSize: 0.08, color: "#FFF", textAlign: .center)],
                devices: [
                    DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.34, y: 0.58, scale: 0.50),
                    DeviceSlot(screenshotFile: "s2.png", mockup: "iPhone 17 Pro Max", x: 0.66, y: 0.64, scale: 0.50)
                ]
            )
        ])
        let (planPath, screenshots) = try writeCompositionPlanAndScreenshots(plan: plan, screenshotFiles: ["s1.png", "s2.png"])
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("Dual View"))
        // Two base64 images embedded
        let dataURICount = html.components(separatedBy: "data:image/png;base64,").count - 1
        #expect(dataURICount >= 2)
    }

    @Test func `composition plan applies center text alignment`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Centered", x: 0.5, y: 0.04, fontSize: 0.08, color: "#FFF", textAlign: .center)],
                devices: []
            )
        ])
        let (planPath, _) = try writeCompositionPlanAndScreenshots(plan: plan)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("text-align:center"))
        #expect(html.contains("translateX(-50%)"))
    }

    @Test func `composition plan applies right text alignment`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Right", x: 0.9, y: 0.04, fontSize: 0.08, color: "#FFF", textAlign: .right)],
                devices: []
            )
        ])
        let (planPath, _) = try writeCompositionPlanAndScreenshots(plan: plan)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("text-align:right"))
        #expect(html.contains("translateX(-100%)"))
    }

    @Test func `composition plan renders device with rotation`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                texts: [],
                devices: [
                    DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.5, rotation: 8.0)
                ]
            )
        ])
        let (planPath, screenshots) = try writeCompositionPlanAndScreenshots(plan: plan, screenshotFiles: ["s1.png"])
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("rotate(8.0deg)"))
    }

    @Test func `composition plan uses canvas dimensions from plan`() async throws {
        let plan = CompositionPlan(
            appName: "Custom",
            canvas: CanvasSize(width: 1290, height: 2796, displayType: "APP_IPHONE_67"),
            defaults: SlideDefaults(
                background: .solid("#111"),
                textColor: "#FFF", subtextColor: "#888",
                accentColor: "#F00", font: "Helvetica"
            ),
            screens: [
                SlideComposition(
                    texts: [TextOverlay(content: "Custom Size", x: 0.065, y: 0.04, fontSize: 0.1, color: "#FFF")],
                    devices: []
                )
            ]
        )
        let (planPath, _) = try writeCompositionPlanAndScreenshots(plan: plan)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("1290"))
        #expect(html.contains("2796"))
        #expect(html.contains("Helvetica"))
    }

    @Test func `composition plan renders multiple screens`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Screen One", x: 0.065, y: 0.04, fontSize: 0.08, color: "#FFF")],
                devices: []
            ),
            SlideComposition(
                background: .gradient(from: "#1B3A5E", to: "#000", angle: 180),
                texts: [TextOverlay(content: "Screen Two", x: 0.065, y: 0.04, fontSize: 0.08, color: "#FFF")],
                devices: []
            )
        ])
        let (planPath, _) = try writeCompositionPlanAndScreenshots(plan: plan)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("Screen One"))
        #expect(html.contains("Screen Two"))
        #expect(html.contains("#1B3A5E"))
    }

    @Test func `composition plan app name in page title`() async throws {
        let plan = makeCompositionPlan(appName: "NexusApp", screens: [
            SlideComposition(texts: [TextOverlay(content: "Hi", x: 0.1, y: 0.1, fontSize: 0.05, color: "#FFF")], devices: [])
        ])
        let (planPath, _) = try writeCompositionPlanAndScreenshots(plan: plan)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("<title>NexusApp"))
    }

    @Test func `composition plan includes export functionality`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(texts: [TextOverlay(content: "Test", x: 0.1, y: 0.1, fontSize: 0.05, color: "#FFF")], devices: [])
        ])
        let (planPath, _) = try writeCompositionPlanAndScreenshots(plan: plan)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("html-to-image"))
        #expect(html.contains("Export"))
        #expect(html.contains("export-slide-"))
    }

    @Test func `composition plan auto-detects format over screen plan`() async throws {
        let plan = makeCompositionPlan(appName: "AutoDetect", screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Detected", x: 0.065, y: 0.04, fontSize: 0.08, color: "#FFF")],
                devices: [DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.8)]
            )
        ])
        let (planPath, screenshots) = try writeCompositionPlanAndScreenshots(plan: plan, screenshotFiles: ["s1.png"])
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"] + screenshots)
        let output = try await cmd.execute()

        #expect(output.contains("app-shots.html"))
        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("Detected"))
        #expect(html.contains("<title>AutoDetect"))
    }

    @Test func `composition plan with default mockup renders mockup frame`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                texts: [],
                devices: [DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.8)]
            )
        ])
        let (planPath, screenshots) = try writeCompositionPlanAndScreenshots(plan: plan, screenshotFiles: ["s1.png"])
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        // No --mockup flag — uses bundled default for composition plan too
        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir] + screenshots)
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("data:image/png;base64,"))
    }

    @Test func `composition plan text overlay uses custom font`() async throws {
        let plan = makeCompositionPlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Custom Font", x: 0.1, y: 0.1, fontSize: 0.08, color: "#FFF", font: "Georgia")],
                devices: []
            )
        ])
        let (planPath, _) = try writeCompositionPlanAndScreenshots(plan: plan)
        let outputDir = makeTempOutputDir()
        defer {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: planPath).deletingLastPathComponent())
            try? FileManager.default.removeItem(atPath: outputDir)
        }

        let cmd = try AppShotsHTML.parse(["--plan", planPath, "--output-dir", outputDir, "--mockup", "none"])
        _ = try await cmd.execute()

        let html = try String(contentsOfFile: "\(outputDir)/app-shots.html", encoding: .utf8)
        #expect(html.contains("Georgia"))
    }
}
