import Foundation

/// Renders gallery panels as HTML matching the gallery-templates-poc structure.
///
/// Uses `cqi` units + `container-type:inline-size` for responsive scaling.
/// Panel aspect ratio: 1320/2868 (iPhone App Store screenshot).
public enum GalleryHTMLRenderer {

    /// Render a single AppShot as an inner panel HTML fragment.
    ///
    /// This is the `.pi` div contents — background + text + device.
    /// The caller wraps it in a panel container.
    public static func renderPanel(
        _ shot: AppShot,
        screenTemplate: ScreenTemplate,
        palette: GalleryPalette
    ) -> String {
        let bg = palette.background

        // Text — headline positioned absolute with cqi units
        let hl = screenTemplate.headline
        let hlSize = fmt(hl.size * 100)
        let hlTop = fmt(hl.y * 100)
        let hlText = (shot.headline ?? "").replacingOccurrences(of: "\n", with: "<br>")

        var textHTML = ""
        textHTML += "<div style=\"position:absolute;top:\(hlTop)%;left:5%;right:5%;z-index:4;"
        textHTML += "font-weight:\(hl.weight);font-size:\(hlSize)cqi;"
        textHTML += "color:#000;line-height:0.92;letter-spacing:-0.03em;"
        textHTML += "text-align:\(hl.align);white-space:pre-line\">"
        textHTML += "\(hlText)</div>"

        // Device — iPhone frame with screenshot
        // Device — wireframe phone with screenshot
        var devHTML = ""
        if let dev = screenTemplate.device {
            let dw = fmt(dev.width * 100)
            let dl = fmt((dev.x - dev.width / 2) * 100)
            let dt = fmt(dev.y * 100)
            let shadow = isLightBackground(bg) ? "0.12" : "0.35"
            let frameBg = isLightBackground(bg) ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.08)"
            let frameBorder = isLightBackground(bg) ? "rgba(0,0,0,0.12)" : "rgba(255,255,255,0.15)"
            let scr = isLightBackground(bg) ? "rgba(255,255,255,0.65)" : "rgba(255,255,255,0.06)"
            let ui = isLightBackground(bg) ? "rgba(0,0,0,0.06)" : "rgba(255,255,255,0.06)"
            let ui2 = isLightBackground(bg) ? "rgba(0,0,0,0.10)" : "rgba(255,255,255,0.09)"
            let uitx = isLightBackground(bg) ? "rgba(0,0,0,0.30)" : "rgba(255,255,255,0.25)"

            // Real frame overlay or CSS wireframe
            let frameOverlay: String
            let outerStyle: String
            if let dataURL = phoneFrameDataURL {
                frameOverlay = "<img src=\"\(dataURL)\" style=\"position:absolute;inset:0;width:100%;height:100%;z-index:2;pointer-events:none\" alt=\"\">"
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)))"
            } else {
                frameOverlay = ""
                outerStyle = "aspect-ratio:1470/3000;position:relative;filter:drop-shadow(0 4px 20px rgba(0,0,0,\(shadow)));background:\(frameBg);border-radius:12%/5.5%;border:1.5px solid \(frameBorder);overflow:hidden"
            }

            devHTML += "<div style=\"position:absolute;left:\(dl)%;top:\(dt)%;width:\(dw)%;z-index:2\">"
            devHTML += "<div style=\"\(outerStyle)\">"
            // Screen area with wireframe UI
            devHTML += "<div style=\"position:absolute;inset:2.6% 2.2%;background:\(scr);border-radius:8%/4%;overflow:hidden;z-index:1\">"
            devHTML += "<div style=\"padding:5% 5% 0;display:flex;justify-content:space-between\">"
            devHTML += "<div style=\"font-size:max(3.5px,1.6cqi);font-weight:600;color:\(uitx);font-family:system-ui\">9:41</div>"
            devHTML += "<div style=\"display:flex;gap:1px;align-items:center\">"
            devHTML += "<div style=\"width:max(3px,1.2cqi);height:max(3px,1.2cqi);border-radius:50%;background:\(uitx)\"></div>"
            devHTML += "<div style=\"width:max(5px,2cqi);height:max(3px,1.2cqi);border-radius:1px;background:\(uitx)\"></div>"
            devHTML += "</div></div>"
            // Mock UI cards
            devHTML += "<div style=\"padding:3% 4% 0\">"
            devHTML += "<div style=\"background:\(ui);border-radius:max(3px,1.5cqi);padding:4% 5%;margin-bottom:2%\">"
            devHTML += "<div style=\"display:flex;gap:3%;align-items:center;margin-bottom:3%\">"
            devHTML += "<div style=\"width:max(6px,3cqi);height:max(6px,3cqi);border-radius:50%;background:\(ui2)\"></div>"
            devHTML += "<div><div style=\"height:max(1.5px,0.7cqi);width:max(14px,7cqi);background:\(ui2);border-radius:1px;margin-bottom:2px\"></div>"
            devHTML += "<div style=\"height:max(1px,0.5cqi);width:max(9px,4.5cqi);background:\(ui2);border-radius:1px\"></div></div></div>"
            devHTML += "<div style=\"aspect-ratio:16/9;background:\(ui2);border-radius:max(2px,1cqi);margin-bottom:3%\"></div>"
            devHTML += "<div style=\"height:max(1.5px,0.7cqi);width:80%;background:\(ui2);border-radius:1px;margin-bottom:2%\"></div>"
            devHTML += "<div style=\"height:max(1px,0.5cqi);width:55%;background:\(ui2);border-radius:1px\"></div></div>"
            devHTML += "<div style=\"background:\(ui);border-radius:max(3px,1.5cqi);padding:4% 5%;margin-bottom:2%\">"
            devHTML += "<div style=\"display:flex;gap:3%\">"
            devHTML += "<div style=\"flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)\"></div>"
            devHTML += "<div style=\"flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)\"></div>"
            devHTML += "<div style=\"flex:1;aspect-ratio:1;background:\(ui2);border-radius:max(2px,1cqi)\"></div></div></div>"
            devHTML += "</div>"
            // Home indicator
            devHTML += "<div style=\"position:absolute;bottom:1.2%;left:30%;right:30%;height:max(1.5px,0.6cqi);background:\(uitx);border-radius:4px\"></div>"
            devHTML += "</div>" // screen area
            devHTML += "\(frameOverlay)</div></div>"
        }

        return "<div class=\"pi\" style=\"background:\(bg);position:relative;overflow:hidden;container-type:inline-size;width:100%;height:100%\">"
            + "\(textHTML)\(devHTML)"
            + "</div>"
    }

    // MARK: - Preview

    /// Render a full HTML preview page for a gallery template — same wireframe phone
    /// as the single template previews. Used in the template browser UI.
    /// Render a full HTML preview page for a gallery template.
    /// Uses the template's actual background and layout to show a realistic preview
    /// with the same wireframe phone + real bezel as single template previews.
    public static func renderPreviewPage(_ galleryTemplate: GalleryTemplate) -> String {
        let screenTemplate = galleryTemplate.screens[.feature]
            ?? galleryTemplate.screens[.hero]
            ?? galleryTemplate.screens.values.first
        guard let st = screenTemplate else { return "" }

        let hl = st.headline
        let bg = galleryTemplate.background
        let isLight = isLightBackground(bg)
        let textColor = isLight ? "#111111" : "#FFFFFF"

        let textSlots = [
            TemplateTextSlot(
                role: .heading,
                preview: galleryTemplate.name,
                x: hl.align == "left" ? 0.06 : 0.5,
                y: hl.y,
                fontSize: hl.size,
                fontWeight: hl.weight,
                color: textColor,
                textAlign: hl.align
            )
        ]
        let deviceSlots: [TemplateDeviceSlot]
        if let dev = st.device {
            deviceSlots = [TemplateDeviceSlot(x: dev.x, y: dev.y, scale: dev.width)]
        } else {
            deviceSlots = []
        }

        // Parse background — try as CSS value, fall back to gradient
        let slideBg: SlideBackground
        if bg.contains("gradient") || bg.contains("#") || bg.contains("rgb") {
            // Use solid with the raw CSS value — TemplateHTMLRenderer will output it directly
            slideBg = .solid(bg)
        } else {
            slideBg = .gradient(from: "#1a1d26", to: "#2a2d38", angle: 180)
        }

        let template = ScreenshotTemplate(
            id: "gallery-preview-\(galleryTemplate.id)",
            name: galleryTemplate.name,
            category: .custom,
            supportedSizes: [.portrait],
            description: galleryTemplate.description,
            background: slideBg,
            textSlots: textSlots,
            deviceSlots: deviceSlots
        )
        return template.previewHTML
    }

    private static func isLightBackground(_ bg: String) -> Bool {
        // Quick heuristic: if it contains light hex colors or named light colors
        let lightPatterns = ["#f", "#F", "#e", "#E", "#d", "#D", "#c", "#C", "#b", "#B", "#a8", "#A8"]
        return lightPatterns.contains(where: { bg.contains($0) })
    }

    // MARK: - Helpers

    /// Base64 data URL of the iPhone frame PNG. Set by infrastructure at startup.
    nonisolated(unsafe) public static var phoneFrameDataURL: String?

    private static func fmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
