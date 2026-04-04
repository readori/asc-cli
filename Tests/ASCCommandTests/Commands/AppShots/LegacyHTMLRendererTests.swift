import Foundation
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct LegacyHTMLRendererTests {

    // MARK: - Helpers

    private func makePlan(
        appName: String = "TestApp",
        screens: [ScreenDesign] = []
    ) -> ScreenshotDesign {
        ScreenshotDesign(
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
    ) -> ScreenDesign {
        ScreenDesign(
            index: index,
            screenshotFile: "screen\(index).png",
            heading: heading,
            subheading: subheading,
            layoutMode: layoutMode,
            visualDirection: "Dark background",
            imagePrompt: "Modern app showcase"
        )
    }

    // MARK: - Basic structure

    @Test func `renders heading and subheading`() {
        let plan = makePlan(screens: [makeScreen(heading: "Amazing", subheading: "Works great")])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("Amazing"))
        #expect(html.contains("Works great"))
    }

    @Test func `app name in page title`() {
        let plan = makePlan(appName: "SuperApp", screens: [makeScreen()])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("<title>SuperApp"))
    }

    @Test func `applies plan colors`() {
        let plan = makePlan(screens: [makeScreen()])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("#0A1628"))
        #expect(html.contains("#4A7CFF"))
        #expect(html.contains("#FFFFFF"))
    }

    // MARK: - Layout modes

    @Test func `renders layout-center class`() {
        let plan = makePlan(screens: [makeScreen(layoutMode: .center)])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("layout-center"))
    }

    @Test func `renders layout-left class`() {
        let plan = makePlan(screens: [makeScreen(layoutMode: .left)])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("layout-left"))
    }

    @Test func `renders layout-tilted class`() {
        let plan = makePlan(screens: [makeScreen(layoutMode: .tilted)])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("layout-tilted"))
    }

    // MARK: - Screenshots

    @Test func `embeds screenshot data URI`() {
        let plan = makePlan(screens: [makeScreen(index: 0)])
        let assets = RenderAssets(
            screenshotDataURIs: ["screen0.png": "data:image/png;base64,FAKEDATA"],
            mockups: [:]
        )
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: assets,
            width: 1320, height: 2868
        )

        #expect(html.contains("data:image/png;base64,FAKEDATA"))
    }

    // MARK: - Mockup

    @Test func `with mockup uses mockup-frame and screen-content classes`() {
        let plan = makePlan(screens: [makeScreen()])
        let assets = RenderAssets(
            screenshotDataURIs: [:],
            mockups: ["__default__": MockupInfo(
                dataURI: "data:image/png;base64,MOCKUP",
                frameWidth: 1470, frameHeight: 3000,
                insetX: 75, insetY: 66
            )]
        )
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: assets,
            width: 1320, height: 2868
        )

        #expect(html.contains("mockup-frame"))
        #expect(html.contains("screen-content"))
    }

    @Test func `without mockup uses box-shadow`() {
        let plan = makePlan(screens: [makeScreen()])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("box-shadow"))
        #expect(!html.contains("mockup-frame"))
    }

    // MARK: - Dimensions

    @Test func `uses provided width and height`() {
        let plan = makePlan(screens: [makeScreen()])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1290, height: 2796
        )

        #expect(html.contains("1290"))
        #expect(html.contains("2796"))
    }

    // MARK: - Export

    @Test func `includes export functionality`() {
        let plan = makePlan(screens: [makeScreen()])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("html-to-image"))
        #expect(html.contains("Export"))
    }

    @Test func `multiple screens all rendered`() {
        let plan = makePlan(screens: [
            makeScreen(index: 0, heading: "First"),
            makeScreen(index: 1, heading: "Second"),
            makeScreen(index: 2, heading: "Third")
        ])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("First"))
        #expect(html.contains("Second"))
        #expect(html.contains("Third"))
    }

    @Test func `escapes HTML in text content`() {
        let plan = makePlan(appName: "Test&App", screens: [
            makeScreen(heading: "<b>Bold</b>", subheading: "\"quotes\"")
        ])
        let html = LegacyHTMLRenderer.render(
            plan: plan, assets: .empty,
            width: 1320, height: 2868
        )

        #expect(html.contains("Test&amp;App"))
        #expect(html.contains("&lt;b&gt;Bold&lt;/b&gt;"))
    }
}
