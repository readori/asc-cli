import ArgumentParser
import Domain
import Foundation
import Infrastructure

struct AppShotsTemplatesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "templates",
        abstract: "Browse and apply screenshot templates",
        subcommands: [AppShotsTemplatesList.self, AppShotsTemplatesGet.self, AppShotsTemplatesApply.self]
    )
}

// MARK: - List

struct AppShotsTemplatesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available screenshot templates"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Filter by size: portrait, landscape, portrait43, square")
    var size: ScreenSize?

    @Flag(name: .long, help: "Include self-contained HTML preview for each template")
    var preview: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        let templates = try await repo.listTemplates(size: size)

        if preview {
            // Include previewHTML in affordances
            let items = templates.map { t -> [String: Any] in
                var affordances = t.affordances
                affordances["previewHTML"] = t.previewHTML
                return [
                    "id": t.id, "name": t.name,
                    "category": t.category.rawValue,
                    "description": t.description,
                    "supportedSizes": t.supportedSizes.map(\.rawValue),
                    "deviceCount": t.deviceCount,
                    "affordances": affordances,
                ]
            }
            let data = try JSONSerialization.data(
                withJSONObject: ["data": items],
                options: globals.pretty ? [.prettyPrinted, .sortedKeys] : []
            )
            return String(data: data, encoding: .utf8) ?? "{}"
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            templates,
            headers: ["ID", "Name", "Category", "Devices"],
            rowMapper: { [$0.id, $0.name, $0.category.rawValue, "\($0.deviceCount)"] }
        )
    }
}

// MARK: - Get

struct AppShotsTemplatesGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get details of a specific template"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Template ID")
    var id: String

    @Flag(name: .long, help: "Output self-contained HTML preview page")
    var preview: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        guard let template = try await repo.getTemplate(id: id) else {
            throw ValidationError("Template '\(id)' not found. Run `asc app-shots templates list` to see available templates.")
        }

        if preview {
            return template.previewHTML
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [template],
            headers: ["ID", "Name", "Category", "Sizes", "Devices"],
            rowMapper: { [$0.id, $0.name, $0.category.rawValue, $0.supportedSizes.map(\.rawValue).joined(separator: ","), "\($0.deviceCount)"] }
        )
    }
}

// MARK: - Apply

struct AppShotsTemplatesApply: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apply",
        abstract: "Apply a template to a screenshot — returns the composed design with preview"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Template ID")
    var id: String

    @Option(name: .long, help: "Path to screenshot file")
    var screenshot: String

    @Option(name: .long, help: "Headline text")
    var headline: String

    @Option(name: .long, help: "Subtitle text")
    var subtitle: String?

    @Option(name: .long, help: "Tagline text (overrides template default)")
    var tagline: String?

    @Option(name: .long, help: "App name")
    var appName: String = "My App"

    @Flag(name: .long, help: "Output self-contained HTML preview with real screenshot")
    var preview: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        guard let template = try await repo.getTemplate(id: id) else {
            throw ValidationError("Template '\(id)' not found. Run `asc app-shots templates list` to see available templates.")
        }

        // For preview mode, use just the filename so the HTML works when opened
        // from the same directory as the screenshot
        let displayFile = preview
            ? URL(fileURLWithPath: screenshot).lastPathComponent
            : screenshot

        if preview {
            let content = TemplateContent(
                headline: headline,
                subtitle: subtitle,
                tagline: tagline,
                screenshotFile: displayFile
            )
            return TemplateHTMLRenderer.renderPage(template, content: content)
        }

        let screen = ScreenDesign(
            index: 0,
            template: template,
            screenshotFile: displayFile,
            heading: headline,
            subheading: subtitle ?? ""
        )

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [screen],
            headers: ["Heading", "Screenshot", "Template", "Complete"],
            rowMapper: { [$0.heading, $0.screenshotFile, $0.template?.name ?? "-", $0.isComplete ? "✓" : "✗"] }
        )
    }
}

// MARK: - ScreenSize ArgumentParser conformance

extension ScreenSize: ExpressibleByArgument {}

