import ArgumentParser
import Domain
import Foundation

struct AppShotsThemesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "themes",
        abstract: "Browse visual themes for screenshot composition",
        subcommands: [AppShotsThemesList.self, AppShotsThemesGet.self, AppShotsThemesApply.self]
    )
}

// MARK: - List

struct AppShotsThemesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available visual themes"
    )

    @OptionGroup var globals: GlobalOptions

    func run() async throws {
        let repo = ClientProvider.makeThemeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ThemeRepository) async throws -> String {
        let themes = try await repo.listThemes()
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            themes,
            headers: ["ID", "Name", "Icon", "Description"],
            rowMapper: { [$0.id, $0.name, $0.icon, $0.description] }
        )
    }
}

// MARK: - Get

struct AppShotsThemesGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get details of a specific theme"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Theme ID")
    var id: String

    @Flag(name: .long, help: "Output the buildContext() prompt string instead of JSON")
    var context: Bool = false

    func run() async throws {
        let repo = ClientProvider.makeThemeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any ThemeRepository) async throws -> String {
        guard let theme = try await repo.getTheme(id: id) else {
            throw ValidationError("Theme '\(id)' not found. Run `asc app-shots themes list` to see available themes.")
        }

        if context {
            return theme.buildContext()
        }

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [theme],
            headers: ["ID", "Name", "Icon", "Description"],
            rowMapper: { [$0.id, $0.name, $0.icon, $0.description] }
        )
    }
}

// MARK: - Apply

struct AppShotsThemesApply: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apply",
        abstract: "Apply a theme to a template — renders deterministic layout, then AI restyles"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Theme ID")
    var theme: String

    @Option(name: .long, help: "Template ID")
    var template: String

    @Option(name: .long, help: "Path to screenshot file")
    var screenshot: String

    @Option(name: .long, help: "Headline text")
    var headline: String = "Your Headline"

    @Option(name: .long, help: "Subtitle text")
    var subtitle: String?

    @Option(name: .long, help: "Tagline text (overrides template default)")
    var tagline: String?

    @Option(name: .long, help: "Canvas width in pixels (default: 1320)")
    var canvasWidth: Int = 1320

    @Option(name: .long, help: "Canvas height in pixels (default: 2868)")
    var canvasHeight: Int = 2868

    func run() async throws {
        let themeRepo = ClientProvider.makeThemeRepository()
        let templateRepo = ClientProvider.makeTemplateRepository()
        print(try await execute(themeRepo: themeRepo, templateRepo: templateRepo))
    }

    func execute(themeRepo: any ThemeRepository, templateRepo: any TemplateRepository) async throws -> String {
        // Resolve template
        guard let tmpl = try await templateRepo.getTemplate(id: template) else {
            throw ValidationError("Template '\(template)' not found. Run `asc app-shots templates list` to see available templates.")
        }

        // Use just the filename — HTML lives alongside screenshots
        let filename = URL(fileURLWithPath: screenshot).lastPathComponent

        // Step 1: Render deterministic HTML from template
        let content = TemplateContent(headline: headline, subtitle: subtitle, tagline: tagline, screenshotFile: filename)
        let baseHTML = TemplateHTMLRenderer.render(tmpl, content: content)

        // Step 2: Compose with theme via provider's AI backend
        let themedHTML = try await themeRepo.compose(
            themeId: theme,
            html: baseHTML,
            canvasWidth: canvasWidth,
            canvasHeight: canvasHeight
        )

        // Wrap in a full HTML page with correct canvas dimensions
        return Self.wrapInPage(themedHTML, width: canvasWidth, height: canvasHeight)
    }

    static func wrapInPage(_ body: String, width: Int, height: Int) -> String {
        """
        <!DOCTYPE html><html><head><meta charset="utf-8">\
        <meta name="viewport" content="width=device-width,initial-scale=1">\
        <title>Themed Screenshot</title>\
        <style>*{margin:0;padding:0;box-sizing:border-box}\
        body{display:flex;justify-content:center;align-items:center;min-height:100vh;background:#111}\
        .preview{width:320px;aspect-ratio:\(width)/\(height);container-type:inline-size}</style>\
        </head><body><div class="preview">\(body)</div></body></html>
        """
    }
}
