import Foundation

/// Renders App Store screenshot screens as HTML.
///
/// **SRP:** Maps domain model data → template context dictionaries.
/// **OCP:** All HTML, CSS colors, and keyframes live in external templates.
///
/// Color scheme (light/dark) is handled entirely by CSS custom properties
/// defined in `theme-vars.html`. Swift only passes `data-theme="light|dark"`.
public enum GalleryHTMLRenderer {

    /// The template repository. Plugins can replace to provide custom templates.
    nonisolated(unsafe) public static var templateRepository: any HTMLTemplateRepository = BundledHTMLTemplateRepository()

    nonisolated(unsafe) public static var phoneFrameDataURL: String?

    // MARK: - Screen Rendering

    /// Render a single AppShot as an HTML fragment for one screen.
    public static func renderScreen(
        _ shot: AppShot,
        screenLayout: ScreenLayout,
        palette: GalleryPalette
    ) -> String {
        let context = buildScreenContext(shot, screenLayout: screenLayout, palette: palette)
        return HTMLComposer.render(loadTemplate("screen"), with: context)
    }

    /// Build the full context dictionary for a screen template.
    public static func buildScreenContext(
        _ shot: AppShot,
        screenLayout: ScreenLayout,
        palette: GalleryPalette
    ) -> [String: Any] {
        let hl = screenLayout.headline
        let pad = 5.0
        let theme = palette.isLight ? "light" : "dark"

        var context: [String: Any] = [
            "background": palette.background,
            "theme": theme,
            "themeVars": loadTemplate("theme-vars"),
        ]

        // Tagline
        if let tgSlot = screenLayout.tagline {
            let tgText = shot.tagline ?? tgSlot.preview ?? ""
            if !tgText.isEmpty {
                context["tagline"] = textSlotContext(tgSlot, content: tgText, color: palette.headlineColor, pad: pad)
            }
        }

        // Headline
        let hlContent = shot.headline ?? hl.preview ?? ""
        if !hlContent.isEmpty {
            context["headline"] = textSlotContext(hl, content: hlContent.replacingOccurrences(of: "\n", with: "<br>"), color: palette.headlineColor, pad: pad)
        }

        // Subheading
        if let subSlot = screenLayout.subheading {
            let subText = shot.body ?? subSlot.preview ?? ""
            if !subText.isEmpty {
                var sub = textSlotContext(subSlot, content: subText.replacingOccurrences(of: "\n", with: "<br>"), color: "", pad: pad)
                sub["padRight"] = fmt(pad + 3)
                context["subheading"] = sub
            }
        }

        // Trust marks
        if let marks = shot.trustMarks, !marks.isEmpty {
            let hlLines = Double(hlContent.components(separatedBy: "\n").count)
            let afterHeading = hl.y * 100 + hlLines * hl.size * 100 * 1.0 + 1
            let markSize = fmt(hl.size * 100 * 0.28)
            context["trustMarksHTML"] = "1"
            context["trustMarks"] = [
                "top": fmt(afterHeading),
                "pad": fmt(pad),
                "items": marks.map { ["text": $0, "fontSize": markSize] },
            ] as [String: Any]
        }

        // Badges
        if !shot.badges.isEmpty {
            context["badges"] = badgeContexts(shot.badges, headlineSlot: hl)
        }

        // Devices
        let devSlots = screenLayout.devices.isEmpty && shot.type == .hero
            ? [DeviceSlot(x: 0.5, y: 0.42, width: 0.65)]
            : screenLayout.devices
        context["devices"] = devSlots.enumerated().map { (devIndex, dev) in
            let screenshotFile = devIndex < shot.screenshots.count ? shot.screenshots[devIndex] : ""
            return deviceContext(dev, screenshot: screenshotFile)
        }

        // Decorations
        if !screenLayout.decorations.isEmpty {
            context["decorations"] = decorationContexts(screenLayout.decorations)
            let hasAnimations = screenLayout.decorations.contains(where: { $0.animation != nil })
            if hasAnimations {
                context["hasAnimations"] = "1"
                context["keyframesHTML"] = loadTemplate("keyframes")
            }
        }

        return context
    }

    // MARK: - Public Element Renderers

    public static func renderTagline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let color = headlineColor ?? (isLight ? "rgba(0,0,0,0.40)" : "rgba(255,255,255,0.45)")
        return HTMLComposer.render(loadTemplate("tagline"), with: textSlotContext(slot, content: content, color: color, pad: pad))
    }

    public static func renderHeadline(_ slot: TextSlot, content: String, isLight: Bool, pad: Double, headlineColor: String? = nil) -> String {
        guard !content.isEmpty else { return "" }
        let color = headlineColor ?? (isLight ? "#000" : "#fff")
        return HTMLComposer.render(loadTemplate("headline"), with: textSlotContext(slot, content: content.replacingOccurrences(of: "\n", with: "<br>"), color: color, pad: pad))
    }

    public static func renderSubheading(_ slot: TextSlot, content: String, isLight: Bool, pad: Double) -> String {
        guard !content.isEmpty else { return "" }
        let bodyColor = isLight ? "#1a1a1a" : "rgba(255,255,255,0.7)"
        var ctx = textSlotContext(slot, content: content.replacingOccurrences(of: "\n", with: "<br>"), color: bodyColor, pad: pad)
        ctx["padRight"] = fmt(pad + 3)
        return HTMLComposer.render(loadTemplate("subheading"), with: ctx)
    }

    public static func renderBadges(_ badges: [String], headlineSlot hl: TextSlot, isLight: Bool) -> String {
        guard !badges.isEmpty else { return "" }
        let template = loadTemplate("badge")
        return badgeContexts(badges, headlineSlot: hl)
            .map { HTMLComposer.render(template, with: $0) }.joined()
    }

    public static func renderTrustMarks(_ marks: [String], headlineSlot hl: TextSlot, headlineContent: String, isLight: Bool) -> String {
        guard !marks.isEmpty else { return "" }
        let pad = 5.0
        let hlLines = Double(headlineContent.components(separatedBy: "\n").count)
        let afterHeading = hl.y * 100 + hlLines * hl.size * 100 * 1.0 + 1
        let markSize = fmt(hl.size * 100 * 0.28)
        let markTemplate = loadTemplate("trust-mark")
        let items = marks.map { mark in
            HTMLComposer.render(markTemplate, with: ["text": mark, "fontSize": markSize])
        }.joined()
        return HTMLComposer.render(loadTemplate("trust-marks-wrapper"), with: [
            "top": fmt(afterHeading), "pad": fmt(pad), "items": items,
        ])
    }

    public static func renderDevice(_ slot: DeviceSlot, screenshot: String, isLight: Bool) -> String {
        let ctx = deviceContext(slot, screenshot: screenshot)
        let template = !screenshot.isEmpty ? "device-screenshot" : "device-wireframe"
        return HTMLComposer.render(loadTemplate(template), with: ctx)
    }

    public static func renderDecorations(_ decorations: [Decoration], isLight: Bool) -> String {
        guard !decorations.isEmpty else { return "" }
        let template = loadTemplate("decoration")
        var html = decorationContexts(decorations)
            .map { HTMLComposer.render(template, with: $0) }.joined()
        if decorations.contains(where: { $0.animation != nil }) {
            html += loadTemplate("keyframes")
        }
        return html
    }

    // MARK: - Page Wrapper

    public static func wrapPage(_ inner: String, fillViewport: Bool = false) -> String {
        let styles = buildPageStyles(fillViewport: fillViewport)
        return HTMLComposer.render(loadTemplate("page-wrapper"), with: ["styles": styles, "inner": inner])
    }

    /// CSS construction stays in Swift — CSS `{` braces conflict with `{{` template syntax.
    public static func buildPageStyles(fillViewport: Bool = false, width: Int = 1320, height: Int = 2868) -> String {
        let previewStyle = fillViewport
            ? "width:100%;height:100%;container-type:inline-size"
            : "width:320px;aspect-ratio:\(width)/\(height);container-type:inline-size"
        let bodyStyle = fillViewport
            ? "margin:0;overflow:hidden"
            : "display:flex;justify-content:center;align-items:center;min-height:100vh;background:#111"
        let htmlHeight = fillViewport ? "html,body{width:100%;height:100%}" : ""
        return "*{margin:0;padding:0;box-sizing:border-box}\(htmlHeight)body{\(bodyStyle)}.preview{\(previewStyle)}"
    }

    public static func loadPageWrapperTemplate() -> String { loadTemplate("page-wrapper") }

    // MARK: - Preview

    public static func renderPreviewPage(_ gallery: Gallery) -> String {
        let screens = gallery.renderAll()
        guard !screens.isEmpty else { return "" }
        let screenTemplate = loadTemplate("preview-screen")
        let screenDivs = screens.map { HTMLComposer.render(screenTemplate, with: ["screen": $0]) }.joined()
        return HTMLComposer.render(loadTemplate("preview-page"), with: ["screenDivs": screenDivs])
    }

    // MARK: - Context Builders (pure data mapping, no HTML, no colors)

    private static func textSlotContext(_ slot: TextSlot, content: String, color: String, pad: Double) -> [String: Any] {
        [
            "top": fmt(slot.y * 100), "pad": fmt(pad),
            "weight": "\(slot.weight)", "fontSize": fmt(slot.size * 100),
            "color": color, "align": slot.align, "content": content,
        ]
    }

    private static func badgeContexts(_ badges: [String], headlineSlot hl: TextSlot) -> [[String: Any]] {
        let badgeTop = hl.y * 100 + 1.0
        return badges.enumerated().map { (i, badge) in
            let bx = hl.align == "left" ? 65.0 + Double(i % 2) * 12.0 : 60.0 + Double(i % 2) * 15.0
            return [
                "left": fmt(bx), "top": fmt(badgeTop + Double(i) * 7.0),
                "fontSize": fmt(hl.size * 100 * 0.28), "text": badge,
            ]
        }
    }

    private static func decorationContexts(_ decorations: [Decoration]) -> [[String: Any]] {
        decorations.enumerated().map { (i, deco) in
            [
                "left": fmt(deco.x * 100), "top": fmt(deco.y * 100),
                "fontSize": fmt(deco.size * 100), "opacity": fmt(deco.opacity),
                "background": deco.background ?? "transparent",
                "color": deco.color ?? "",
                "useDefaultColor": deco.color == nil ? "1" : "",
                "borderRadius": deco.borderRadius ?? "50%",
                "animStyle": deco.animation.map { "animation:td-\($0.rawValue) \(3 + i % 4)s ease-in-out infinite;" } ?? "",
                "content": deco.shape.displayCharacter,
            ]
        }
    }

    private static func deviceContext(_ slot: DeviceSlot, screenshot: String) -> [String: Any] {
        let dl = fmt((slot.x - slot.width / 2) * 100)
        let dt = fmt(slot.y * 100)
        let dw = fmt(slot.width * 100)

        if !screenshot.isEmpty {
            return ["left": dl, "top": dt, "width": dw, "hasScreenshot": "1", "screenshot": screenshot]
        } else {
            let frameOverlay: String
            let frameStyle: String
            if let dataURL = phoneFrameDataURL {
                frameOverlay = HTMLComposer.render(loadTemplate("frame-overlay"), with: ["dataURL": dataURL])
                frameStyle = ""
            } else {
                frameOverlay = ""
                frameStyle = "background:var(--frame-bg);border-radius:12%/5.5%;border:1.5px solid var(--frame-border);overflow:hidden"
            }
            let wireframeHTML = loadTemplate("wireframe")
            return [
                "left": dl, "top": dt, "width": dw, "hasWireframe": "1",
                "frameStyle": frameStyle,
                "wireframeHTML": wireframeHTML,
                "frameOverlay": frameOverlay,
            ]
        }
    }

    // MARK: - Helpers

    static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    static func loadTemplate(_ name: String) -> String {
        templateRepository.template(named: name) ?? ""
    }
}
