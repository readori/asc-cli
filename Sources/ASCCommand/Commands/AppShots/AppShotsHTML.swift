import ArgumentParser
import CoreGraphics
import Domain
import Foundation
import ImageIO

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

    @Option(name: .long, help: "Path to a device mockup frame PNG (transparent background). Screenshot is positioned inside.")
    var mockup: String?

    @Option(name: .long, help: "Screen area X inset in pixels from mockup edge (default: auto-detect from devices.json or 5.2%)")
    var screenInsetX: Int?

    @Option(name: .long, help: "Screen area Y inset in pixels from mockup edge (default: auto-detect from devices.json or 2.2%)")
    var screenInsetY: Int?

    @Argument(help: "Screenshot files — omit to auto-discover *.png/*.jpg from the plan's directory")
    var screenshots: [String] = []

    func run() async throws {
        print(try await execute())
    }

    func execute() async throws -> String {
        let effectiveWidth = deviceType.map { $0.dimensions.width } ?? outputWidth
        let effectiveHeight = deviceType.map { $0.dimensions.height } ?? outputHeight

        // Load plan
        let planURL = URL(fileURLWithPath: plan)
        let planData = try Data(contentsOf: planURL)
        let loadedPlan = try JSONDecoder().decode(ScreenPlan.self, from: planData)

        // Resolve screenshots
        let resolvedScreenshots: [String]
        if screenshots.isEmpty {
            let planDir = planURL.deletingLastPathComponent()
            let contents = (try? FileManager.default.contentsOfDirectory(at: planDir, includingPropertiesForKeys: nil)) ?? []
            resolvedScreenshots = contents
                .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
                .map { $0.path }
        } else {
            resolvedScreenshots = screenshots
        }

        // Build screenshot data map: filename → base64 data URI
        var screenshotDataURIs: [String: String] = [:]
        for path in resolvedScreenshots {
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ValidationError("Screenshot file not found: \(path)")
            }
            let data = try Data(contentsOf: url)
            let ext = url.pathExtension.lowercased()
            let mime = ext == "jpg" || ext == "jpeg" ? "image/jpeg" : "image/png"
            screenshotDataURIs[url.lastPathComponent] = "data:\(mime);base64,\(data.base64EncodedString())"
        }

        // Load mockup frame if provided
        let mockupInfo = try resolveMockup()

        // Generate HTML
        let html = generateHTML(
            plan: loadedPlan,
            screenshotDataURIs: screenshotDataURIs,
            mockupInfo: mockupInfo,
            width: effectiveWidth,
            height: effectiveHeight
        )

        // Write output
        let outputDirURL = URL(fileURLWithPath: outputDir)
        try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true)
        let htmlPath = outputDirURL.appendingPathComponent("app-shots.html")
        try html.write(to: htmlPath, atomically: true, encoding: .utf8)

        return formatOutput(path: htmlPath.path)
    }

    /// Mockup frame data: base64 URI + screen position offsets.
    struct MockupInfo {
        let dataURI: String
        let frameWidth: Int
        let frameHeight: Int
        let insetX: Int
        let insetY: Int
    }

    private func resolveMockup() throws -> MockupInfo? {
        guard let mockupPath = mockup else { return nil }
        let url = URL(fileURLWithPath: mockupPath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError("Mockup file not found: \(mockupPath)")
        }
        let data = try Data(contentsOf: url)
        let dataURI = "data:image/png;base64,\(data.base64EncodedString())"

        // Get image dimensions via CoreGraphics
        let (frameW, frameH) = imageSize(data: data)

        // Resolve screen insets: CLI flags > devices.json > percentage fallback
        let insetX: Int
        let insetY: Int
        if let x = screenInsetX, let y = screenInsetY {
            insetX = x
            insetY = y
        } else if let devicesInset = lookupDevicesJSON(mockupPath: mockupPath) {
            insetX = screenInsetX ?? devicesInset.x
            insetY = screenInsetY ?? devicesInset.y
        } else {
            // Default: ~5.2% X, ~2.2% Y (calibrated for modern iPhones)
            insetX = screenInsetX ?? Int(Double(frameW) * 0.052)
            insetY = screenInsetY ?? Int(Double(frameH) * 0.022)
        }

        return MockupInfo(dataURI: dataURI, frameWidth: frameW, frameHeight: frameH, insetX: insetX, insetY: insetY)
    }

    /// Reads image pixel dimensions from PNG/JPEG data.
    private func imageSize(data: Data) -> (width: Int, height: Int) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int,
              let h = props[kCGImagePropertyPixelHeight] as? Int else {
            return (0, 0)
        }
        return (w, h)
    }

    /// Looks up screen insets from a `devices.json` next to the mockup file or in known locations.
    private func lookupDevicesJSON(mockupPath: String) -> (x: Int, y: Int)? {
        let mockupURL = URL(fileURLWithPath: mockupPath)
        let mockupFilename = mockupURL.lastPathComponent

        // Search for devices.json in the mockup's parent directories (up to 4 levels)
        var searchDir = mockupURL.deletingLastPathComponent()
        for _ in 0..<4 {
            let candidate = searchDir.appendingPathComponent("devices.json")
            if let data = try? Data(contentsOf: candidate),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Search by filename match in path values
                for (_, deviceInfo) in json {
                    guard let info = deviceInfo as? [String: Any],
                          let path = info["path"] as? String,
                          path.contains(mockupFilename.replacingOccurrences(of: ".png", with: "")),
                          let x = info["screenInsetX"] as? Int,
                          let y = info["screenInsetY"] as? Int else { continue }
                    return (x, y)
                }
            }
            searchDir = searchDir.deletingLastPathComponent()
        }
        return nil
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

    // MARK: - HTML Generation

    private func generateHTML(
        plan: ScreenPlan,
        screenshotDataURIs: [String: String],
        mockupInfo: MockupInfo?,
        width: Int,
        height: Int
    ) -> String {
        let screenshotCards = plan.screens.map { screen in
            let dataURI = matchScreenshot(screen: screen, dataURIs: screenshotDataURIs)
            return renderScreenCard(screen: screen, dataURI: dataURI, mockupInfo: mockupInfo, plan: plan, width: width, height: height)
        }.joined(separator: "\n")

        let aspectRatio = Double(width) / Double(height)

        // Compute device CSS dimensions based on mockup or defaults
        let deviceCSS: String
        if let m = mockupInfo {
            let screenW = m.frameWidth - 2 * m.insetX
            let screenH = m.frameHeight - 2 * m.insetY
            let insetXPct = Double(m.insetX) / Double(m.frameWidth) * 100
            let insetYPct = Double(m.insetY) / Double(m.frameHeight) * 100
            let screenWPct = Double(screenW) / Double(m.frameWidth) * 100
            let screenHPct = Double(screenH) / Double(m.frameHeight) * 100
            let borderRadiusPct = 13.8  // Modern iPhone corner radius as % of frame width
            deviceCSS = """
            .slide .phone .device {
                position: relative;
            }
            .slide .phone .device .mockup-frame {
                display: block;
                width: 100%;
                height: 100%;
                position: relative;
                z-index: 2;
                pointer-events: none;
            }
            .slide .phone .device .screen-content {
                position: absolute;
                left: \(String(format: "%.2f", insetXPct))%;
                top: \(String(format: "%.2f", insetYPct))%;
                width: \(String(format: "%.2f", screenWPct))%;
                height: \(String(format: "%.2f", screenHPct))%;
                z-index: 1;
                border-radius: \(String(format: "%.1f", borderRadiusPct))% / \(String(format: "%.1f", borderRadiusPct * Double(m.frameWidth) / Double(m.frameHeight)))%;
                overflow: hidden;
            }
            .slide .phone .device .screen-content img {
                display: block;
                width: 100%;
                height: 100%;
                object-fit: cover;
            }
            """
        } else {
            deviceCSS = """
            .slide .phone .device {
                position: relative;
                border-radius: \(Int(Double(width) * 0.06))px;
                overflow: hidden;
                box-shadow: 0 \(width / 30)px \(width / 10)px rgba(0,0,0,0.5);
            }
            .slide .phone .device img {
                display: block;
                width: 100%;
                height: 100%;
                object-fit: cover;
            }
            """
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>\(escapeHTML(plan.appName)) — App Store Screenshots</title>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/html-to-image/1.11.11/html-to-image.min.js"></script>
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', sans-serif;
            background: #1a1a2e;
            color: #e0e0e0;
            padding: 40px 20px;
        }

        .toolbar {
            text-align: center;
            margin-bottom: 40px;
        }

        .toolbar h1 {
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 8px;
        }

        .toolbar p {
            font-size: 14px;
            color: #888;
            margin-bottom: 20px;
        }

        .toolbar button {
            background: \(plan.colors.accent);
            color: #fff;
            border: none;
            padding: 12px 32px;
            border-radius: 10px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            margin: 0 8px;
            transition: opacity 0.2s;
        }

        .toolbar button:hover { opacity: 0.85; }
        .toolbar button:disabled { opacity: 0.4; cursor: not-allowed; }

        .toolbar .size-info {
            display: inline-block;
            background: rgba(255,255,255,0.08);
            padding: 6px 16px;
            border-radius: 8px;
            font-size: 13px;
            color: #aaa;
            margin-left: 12px;
        }

        .grid {
            display: flex;
            flex-wrap: wrap;
            gap: 24px;
            justify-content: center;
            max-width: 1400px;
            margin: 0 auto;
        }

        .card {
            background: rgba(255,255,255,0.04);
            border-radius: 16px;
            padding: 16px;
            text-align: center;
        }

        .card .label {
            font-size: 13px;
            color: #888;
            margin-bottom: 8px;
        }

        /* Preview container — scales the full-resolution slide to fit */
        .preview-wrap {
            width: 280px;
            height: \(Int(280.0 / aspectRatio))px;
            overflow: hidden;
            border-radius: 12px;
            position: relative;
        }

        .preview-wrap .slide {
            transform-origin: top left;
        }

        /* Full-resolution slide — rendered at actual pixel size */
        .slide {
            width: \(width)px;
            height: \(height)px;
            position: relative;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: flex-start;
        }

        .slide .bg-glow {
            position: absolute;
            width: 60%;
            height: 40%;
            top: 35%;
            left: 50%;
            transform: translateX(-50%);
            border-radius: 50%;
            filter: blur(\(width / 4)px);
            opacity: 0.3;
            pointer-events: none;
        }

        .slide .caption {
            position: relative;
            z-index: 2;
            text-align: center;
            padding-top: \(Int(Double(height) * 0.06))px;
        }

        .slide .caption h2 {
            font-weight: 700;
            line-height: 1.1;
            letter-spacing: -0.02em;
        }

        .slide .caption p {
            font-weight: 400;
            line-height: 1.3;
            margin-top: \(Int(Double(height) * 0.012))px;
        }

        .slide .phone {
            position: relative;
            z-index: 2;
            flex: 1;
            display: flex;
            align-items: flex-end;
            justify-content: center;
            padding-bottom: 0;
        }

        \(deviceCSS)

        /* Layout: center */
        .layout-center .phone .device {
            width: \(Int(Double(width) * 0.78))px;
            height: \(Int(Double(height) * 0.72))px;
        }

        .layout-center .caption h2 { font-size: \(Int(Double(width) * 0.085))px; }
        .layout-center .caption p  { font-size: \(Int(Double(width) * 0.04))px; }

        /* Layout: tilted */
        .layout-tilted .phone .device {
            width: \(Int(Double(width) * 0.82))px;
            height: \(Int(Double(height) * 0.72))px;
            transform: rotate(-6deg) translateY(\(Int(Double(height) * 0.02))px);
        }

        .layout-tilted .caption h2 { font-size: \(Int(Double(width) * 0.095))px; }
        .layout-tilted .caption p  { font-size: \(Int(Double(width) * 0.042))px; }

        /* Layout: left */
        .layout-left {
            flex-direction: row !important;
            align-items: center !important;
        }

        .layout-left .caption {
            text-align: left;
            padding: 0 \(Int(Double(width) * 0.06))px;
            flex: 1;
        }

        .layout-left .caption h2 { font-size: \(Int(Double(width) * 0.08))px; }
        .layout-left .caption p  { font-size: \(Int(Double(width) * 0.038))px; }

        .layout-left .phone {
            flex: none;
            align-items: center;
        }

        .layout-left .phone .device {
            width: \(Int(Double(width) * 0.52))px;
            height: \(Int(Double(height) * 0.72))px;
        }

        /* Off-screen export container */
        .export-container {
            position: absolute;
            left: -99999px;
            top: 0;
        }

        .status {
            text-align: center;
            margin-top: 20px;
            font-size: 14px;
            color: #888;
            min-height: 20px;
        }
        </style>
        </head>
        <body>
        <div class="toolbar">
            <h1>\(escapeHTML(plan.appName))</h1>
            <p>\(escapeHTML(plan.tagline))</p>
            <button onclick="exportAll()">Export All PNGs</button>
            <span class="size-info">\(width) × \(height)</span>
        </div>
        <div class="status" id="status"></div>

        <div class="grid">
        \(screenshotCards)
        </div>

        <!-- Off-screen full-resolution slides for export -->
        <div class="export-container" id="exportContainer">
        \(plan.screens.map { screen in
            let dataURI = matchScreenshot(screen: screen, dataURIs: screenshotDataURIs)
            return renderExportSlide(screen: screen, dataURI: dataURI, mockupInfo: mockupInfo, plan: plan, width: width, height: height)
        }.joined(separator: "\n"))
        </div>

        <script>
        const W = \(width);
        const H = \(height);

        // Scale previews to fit their containers
        document.querySelectorAll('.preview-wrap .slide').forEach(el => {
            const containerWidth = 280;
            const scale = containerWidth / W;
            el.style.transform = 'scale(' + scale + ')';
        });

        async function exportSingle(index) {
            const el = document.getElementById('export-slide-' + index);
            if (!el) return;

            // Move on-screen momentarily
            const container = document.getElementById('exportContainer');
            container.style.left = '0px';
            container.style.opacity = '0';
            container.style.zIndex = '-1';

            // Warm-up call (ensures fonts/images are loaded)
            await htmlToImage.toPng(el, { width: W, height: H, pixelRatio: 1, cacheBust: true });
            // Actual export
            const dataUrl = await htmlToImage.toPng(el, { width: W, height: H, pixelRatio: 1, cacheBust: true });

            // Move back off-screen
            container.style.left = '-99999px';

            // Download
            const link = document.createElement('a');
            link.download = 'screen-' + index + '-' + W + 'x' + H + '.png';
            link.href = dataUrl;
            link.click();
        }

        async function exportAll() {
            const btn = document.querySelector('.toolbar button');
            const status = document.getElementById('status');
            btn.disabled = true;

            const indices = [\(plan.screens.map { "\($0.index)" }.joined(separator: ", "))];
            for (let i = 0; i < indices.length; i++) {
                status.textContent = 'Exporting screen ' + (i + 1) + ' of ' + indices.length + '...';
                await exportSingle(indices[i]);
                // Brief delay between exports
                await new Promise(r => setTimeout(r, 300));
            }

            status.textContent = 'All ' + indices.length + ' screenshots exported!';
            btn.disabled = false;
            setTimeout(() => { status.textContent = ''; }, 3000);
        }
        </script>
        </body>
        </html>
        """
    }

    private func renderDeviceHTML(dataURI: String?, mockupInfo: MockupInfo?, plan: ScreenPlan, screenIndex: Int) -> String {
        if let m = mockupInfo {
            let screenshotTag: String
            if let uri = dataURI {
                screenshotTag = "<img src=\"\(uri)\" alt=\"Screen \(screenIndex)\">"
            } else {
                screenshotTag = "<div style=\"width:100%;height:100%;background:\(plan.colors.accent);opacity:0.3;\"></div>"
            }
            return """
            <div class="device">
                <div class="screen-content">\(screenshotTag)</div>
                <img class="mockup-frame" src="\(m.dataURI)" alt="Device frame">
            </div>
            """
        } else {
            if let uri = dataURI {
                return """
                <div class="device"><img src="\(uri)" alt="Screen \(screenIndex)"></div>
                """
            } else {
                return """
                <div class="device"><div style="width:100%;height:100%;background:\(plan.colors.accent);opacity:0.3;"></div></div>
                """
            }
        }
    }

    private func renderScreenCard(
        screen: ScreenConfig,
        dataURI: String?,
        mockupInfo: MockupInfo?,
        plan: ScreenPlan,
        width: Int,
        height: Int
    ) -> String {
        let deviceHTML = renderDeviceHTML(dataURI: dataURI, mockupInfo: mockupInfo, plan: plan, screenIndex: screen.index)

        return """
        <div class="card">
            <div class="label">Screen \(screen.index)\(screen.index == 0 ? " (Hero)" : "")</div>
            <div class="preview-wrap">
                <div class="slide layout-\(screen.layoutMode.rawValue)" style="background:\(plan.colors.primary);">
                    <div class="bg-glow" style="background:\(plan.colors.accent);"></div>
                    <div class="caption">
                        <h2 style="color:\(plan.colors.text);">\(escapeHTML(screen.heading))</h2>
                        <p style="color:\(plan.colors.subtext);">\(escapeHTML(screen.subheading))</p>
                    </div>
                    <div class="phone">
                        \(deviceHTML)
                    </div>
                </div>
            </div>
            <button onclick="exportSingle(\(screen.index))" style="margin-top:10px;background:\(plan.colors.accent);color:#fff;border:none;padding:8px 20px;border-radius:8px;cursor:pointer;font-size:13px;">Export</button>
        </div>
        """
    }

    private func renderExportSlide(
        screen: ScreenConfig,
        dataURI: String?,
        mockupInfo: MockupInfo?,
        plan: ScreenPlan,
        width: Int,
        height: Int
    ) -> String {
        let deviceHTML = renderDeviceHTML(dataURI: dataURI, mockupInfo: mockupInfo, plan: plan, screenIndex: screen.index)

        return """
        <div id="export-slide-\(screen.index)" class="slide layout-\(screen.layoutMode.rawValue)" style="background:\(plan.colors.primary);">
            <div class="bg-glow" style="background:\(plan.colors.accent);"></div>
            <div class="caption">
                <h2 style="color:\(plan.colors.text);">\(escapeHTML(screen.heading))</h2>
                <p style="color:\(plan.colors.subtext);">\(escapeHTML(screen.subheading))</p>
            </div>
            <div class="phone">
                \(deviceHTML)
            </div>
        </div>
        """
    }

    /// Matches a screenshot file to a screen config by filename, falling back to index order.
    private func matchScreenshot(screen: ScreenConfig, dataURIs: [String: String]) -> String? {
        if let uri = dataURIs[screen.screenshotFile] {
            return uri
        }
        let sorted = dataURIs.keys.sorted()
        if screen.index < sorted.count {
            return dataURIs[sorted[screen.index]]
        }
        return nil
    }

    private func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
