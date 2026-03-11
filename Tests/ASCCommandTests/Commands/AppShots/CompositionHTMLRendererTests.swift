import Foundation
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct CompositionHTMLRendererTests {

    // MARK: - Helpers

    private func makePlan(
        appName: String = "TestApp",
        width: Int = 1320,
        height: Int = 2868,
        font: String = "Inter",
        accentColor: String = "#4A7CFF",
        screens: [SlideComposition] = []
    ) -> CompositionPlan {
        CompositionPlan(
            appName: appName,
            canvas: CanvasSize(width: width, height: height),
            defaults: SlideDefaults(
                background: .solid("#000000"),
                textColor: "#FFFFFF",
                subtextColor: "#A8B8D0",
                accentColor: accentColor,
                font: font
            ),
            screens: screens
        )
    }

    // MARK: - Background rendering

    @Test func `renders gradient background as linear-gradient CSS`() {
        let plan = makePlan(screens: [
            SlideComposition(
                background: .gradient(from: "#2A1B5E", to: "#000", angle: 135),
                texts: [], devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("linear-gradient(135deg"))
        #expect(html.contains("#2A1B5E"))
    }

    @Test func `renders solid background from defaults when slide has no background`() {
        let plan = makePlan(screens: [
            SlideComposition(texts: [], devices: [])
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("background:#000000"))
    }

    @Test func `slide background overrides default background`() {
        let plan = makePlan(screens: [
            SlideComposition(
                background: .solid("#FF0000"),
                texts: [], devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("#FF0000"))
    }

    // MARK: - Text overlays

    @Test func `renders text overlays with correct positioning`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Hero Title", x: 0.065, y: 0.04, fontSize: 0.1, fontWeight: 800, color: "#FFFFFF")],
                devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("Hero Title"))
        #expect(html.contains("font-weight:800"))
        // x: 0.065 * 1320 = 85.8 → 85
        #expect(html.contains("left:85px"))
        // y: 0.04 * 2868 = 114.72 → 114
        #expect(html.contains("top:114px"))
        // fontSize: 0.1 * 1320 = 132
        #expect(html.contains("font-size:132px"))
    }

    @Test func `center text alignment adds translateX -50%`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Centered", x: 0.5, y: 0.04, fontSize: 0.08, color: "#FFF", textAlign: .center)],
                devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("text-align:center"))
        #expect(html.contains("translateX(-50%)"))
    }

    @Test func `right text alignment adds translateX -100%`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Right", x: 0.9, y: 0.04, fontSize: 0.08, color: "#FFF", textAlign: .right)],
                devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("text-align:right"))
        #expect(html.contains("translateX(-100%)"))
    }

    @Test func `left alignment adds no transform`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Left", x: 0.065, y: 0.04, fontSize: 0.08, color: "#FFF", textAlign: .left)],
                devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("Left"))
        #expect(!html.contains("translateX"))
    }

    @Test func `text overlay uses custom font over default`() {
        let plan = makePlan(font: "Inter", screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Custom", x: 0.1, y: 0.1, fontSize: 0.08, color: "#FFF", font: "Georgia")],
                devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("'Georgia'"))
    }

    @Test func `text overlay falls back to default font when nil`() {
        let plan = makePlan(font: "Roboto", screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Default", x: 0.1, y: 0.1, fontSize: 0.08, color: "#FFF")],
                devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("'Roboto'"))
    }

    // MARK: - Device slots

    @Test func `renders device at correct position and size`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [],
                devices: [DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.85)]
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        // width: 0.85 * 1320 = 1122
        #expect(html.contains("width:1122px"))
        // left: 0.5 * 1320 = 660
        #expect(html.contains("left:660px"))
        // top: 0.6 * 2868 = 1720.8 → 1720
        #expect(html.contains("top:1720px"))
    }

    @Test func `device with rotation includes rotate transform`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [],
                devices: [DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.5, rotation: 8.0)]
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("rotate(8.0deg)"))
    }

    @Test func `device without rotation has no rotate in transform`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [],
                devices: [DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.5)]
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(!html.contains("rotate"))
    }

    @Test func `device embeds screenshot data URI when available`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [],
                devices: [DeviceSlot(screenshotFile: "hero.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.8)]
            )
        ])
        let assets = RenderAssets(
            screenshotDataURIs: ["hero.png": "data:image/png;base64,FAKEPNG"],
            mockups: [:]
        )
        let html = CompositionHTMLRenderer.render(plan: plan, assets: assets)

        #expect(html.contains("data:image/png;base64,FAKEPNG"))
    }

    @Test func `device with mockup renders frame and screen area`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [],
                devices: [DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.8)]
            )
        ])
        let assets = RenderAssets(
            screenshotDataURIs: ["s1.png": "data:image/png;base64,SCREEN"],
            mockups: ["iPhone 17 Pro Max": MockupInfo(
                dataURI: "data:image/png;base64,FRAME",
                frameWidth: 1470, frameHeight: 3000,
                insetX: 75, insetY: 66
            )]
        )
        let html = CompositionHTMLRenderer.render(plan: plan, assets: assets)

        #expect(html.contains("data:image/png;base64,FRAME"))
        #expect(html.contains("data:image/png;base64,SCREEN"))
    }

    @Test func `device fill content mode uses cover object-fit`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [],
                devices: [DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.5, y: 0.6, scale: 0.8, contentMode: .fill)]
            )
        ])
        let assets = RenderAssets(
            screenshotDataURIs: ["s1.png": "data:image/png;base64,X"],
            mockups: ["iPhone 17 Pro Max": MockupInfo(
                dataURI: "data:image/png;base64,F",
                frameWidth: 1470, frameHeight: 3000,
                insetX: 75, insetY: 66
            )]
        )
        let html = CompositionHTMLRenderer.render(plan: plan, assets: assets)

        #expect(html.contains("object-fit:cover"))
    }

    // MARK: - Page structure

    @Test func `page title includes app name`() {
        let plan = makePlan(appName: "NexusApp", screens: [])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("<title>NexusApp"))
    }

    @Test func `canvas dimensions set slide size`() {
        let plan = makePlan(width: 1290, height: 2796, screens: [
            SlideComposition(texts: [], devices: [])
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("width: 1290px"))
        #expect(html.contains("height: 2796px"))
        #expect(html.contains("const W = 1290"))
        #expect(html.contains("H = 2796"))
    }

    @Test func `includes html-to-image script for export`() {
        let plan = makePlan(screens: [])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("html-to-image"))
        #expect(html.contains("exportAll"))
        #expect(html.contains("exportSingle"))
    }

    @Test func `renders multiple screens with correct indices`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [TextOverlay(content: "First", x: 0.1, y: 0.04, fontSize: 0.08, color: "#FFF")],
                devices: []
            ),
            SlideComposition(
                texts: [TextOverlay(content: "Second", x: 0.1, y: 0.04, fontSize: 0.08, color: "#FFF")],
                devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("First"))
        #expect(html.contains("Second"))
        #expect(html.contains("export-slide-0"))
        #expect(html.contains("export-slide-1"))
    }

    @Test func `accent color used for export button`() {
        let plan = makePlan(accentColor: "#FF5500", screens: [])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("#FF5500"))
    }

    @Test func `loads Google Font for default font`() {
        let plan = makePlan(font: "Montserrat", screens: [])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(html.contains("fonts.googleapis.com"))
        #expect(html.contains("Montserrat"))
    }

    @Test func `escapes HTML in text content`() {
        let plan = makePlan(appName: "App <script>alert(1)</script>", screens: [
            SlideComposition(
                texts: [TextOverlay(content: "Hello & \"World\"", x: 0.1, y: 0.1, fontSize: 0.08, color: "#FFF")],
                devices: []
            )
        ])
        let html = CompositionHTMLRenderer.render(plan: plan, assets: .empty)

        #expect(!html.contains("<script>alert"))
        #expect(html.contains("&lt;script&gt;"))
        #expect(html.contains("Hello &amp; &quot;World&quot;"))
    }

    @Test func `multiple devices on one slide both rendered`() {
        let plan = makePlan(screens: [
            SlideComposition(
                texts: [],
                devices: [
                    DeviceSlot(screenshotFile: "s1.png", mockup: "iPhone 17 Pro Max", x: 0.34, y: 0.58, scale: 0.50),
                    DeviceSlot(screenshotFile: "s2.png", mockup: "iPhone 17 Pro Max", x: 0.66, y: 0.64, scale: 0.50)
                ]
            )
        ])
        let assets = RenderAssets(
            screenshotDataURIs: ["s1.png": "data:image/png;base64,A", "s2.png": "data:image/png;base64,B"],
            mockups: [:]
        )
        let html = CompositionHTMLRenderer.render(plan: plan, assets: assets)

        #expect(html.contains("data:image/png;base64,A"))
        #expect(html.contains("data:image/png;base64,B"))
    }
}
