import ArgumentParser
import Domain
import Foundation

struct AppShotsGenerate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate App Store screenshot images using Gemini AI"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Path to plan.json written by the asc-app-shots skill")
    var plan: String

    @Option(name: .long, help: "Gemini API key (falls back to GEMINI_API_KEY env var)")
    var geminiApiKey: String?

    @Option(name: .long, help: "Gemini image generation model to use")
    var model: String = "gemini-3.1-flash-image-preview"

    @Option(name: .long, help: "Directory to write generated PNG images (created if needed)")
    var outputDir: String = "app-shots-output"

    @Argument(help: "Screenshot files matched to screens by filename or index order")
    var screenshots: [String] = []

    func run() async throws {
        let resolvedKey = geminiApiKey ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        guard let apiKey = resolvedKey, !apiKey.isEmpty else {
            throw ValidationError("Gemini API key required. Use --gemini-api-key or set GEMINI_API_KEY env var.")
        }
        let repo = ClientProvider.makeScreenshotGenerationRepository(apiKey: apiKey, model: model)
        print(try await execute(repo: repo))
    }

    func execute(repo: any ScreenshotGenerationRepository) async throws -> String {
        // Load plan
        let planURL = URL(fileURLWithPath: plan)
        let planData = try Data(contentsOf: planURL)
        let loadedPlan = try JSONDecoder().decode(ScreenPlan.self, from: planData)

        // Build screenshot URLs, validate they exist
        var screenshotURLs: [URL] = []
        for path in screenshots {
            let fileURL = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw ValidationError("Screenshot file not found: \(path)")
            }
            screenshotURLs.append(fileURL)
        }

        // Create output directory
        let outputDirURL = URL(fileURLWithPath: outputDir)
        try FileManager.default.createDirectory(at: outputDirURL, withIntermediateDirectories: true)

        // Generate images (parallel Gemini calls)
        let images = try await repo.generateImages(plan: loadedPlan, screenshotURLs: screenshotURLs)

        // Write each image as screen-{index}.png
        var entries: [(index: Int, path: String)] = []
        for (index, data) in images.sorted(by: { $0.key < $1.key }) {
            let fileName = "screen-\(index).png"
            let fileURL = outputDirURL.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            entries.append((index: index, path: fileURL.path))
        }

        return formatOutput(entries: entries)
    }

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
            // JSON
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
