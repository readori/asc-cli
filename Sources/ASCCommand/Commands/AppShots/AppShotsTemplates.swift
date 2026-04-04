import ArgumentParser
import Domain
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

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        let templates = try await repo.listTemplates(size: size)
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

    @Option(name: .long, help: "Output preview in format: html (self-contained page) or png (save to file)")
    var preview: PreviewFormat?

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        let output = try await execute(repo: repo)
        print(output)
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        guard let template = try await repo.getTemplate(id: id) else {
            throw ValidationError("Template '\(id)' not found. Run `asc app-shots templates list` to see available templates.")
        }

        if let format = preview {
            switch format {
            case .html:
                return template.previewHTML
            case .png:
                // Save HTML to temp file, render to PNG via headless browser would be ideal
                // For now: save HTML and tell user to open it
                let path = ".asc/template-preview-\(id).html"
                try template.previewHTML.write(toFile: path, atomically: true, encoding: .utf8)
                return "{\"preview\":\"\(path)\",\"format\":\"html\",\"hint\":\"Open in browser to view. PNG rendering requires a headless browser.\"}"
            }
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
        abstract: "Apply a template to a screenshot — returns a previewable screen design"
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

    @Option(name: .long, help: "App name")
    var appName: String = "My App"

    func run() async throws {
        let repo = ClientProvider.makeTemplateRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any TemplateRepository) async throws -> String {
        guard let template = try await repo.getTemplate(id: id) else {
            throw ValidationError("Template '\(id)' not found. Run `asc app-shots templates list` to see available templates.")
        }

        let screen = ScreenDesign(
            index: 0,
            template: template,
            screenshotFile: screenshot,
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

enum PreviewFormat: String, ExpressibleByArgument, CaseIterable {
    case html
    case png
}
