import Foundation
import Testing
@testable import Domain

@Suite
struct CompositionPlanTests {

    // MARK: - JSON round-trip

    @Test func `plan encodes and decodes with all fields`() throws {
        let plan = CompositionPlan(
            appName: "TestApp",
            canvas: CanvasSize(width: 1320, height: 2868),
            defaults: SlideDefaults(
                background: .solid("#0A1628"),
                textColor: "#FFFFFF",
                subtextColor: "#A8B8D0",
                accentColor: "#4A7CFF",
                font: "Inter"
            ),
            screens: [
                SlideComposition(
                    texts: [
                        TextOverlay(
                            content: "All Your Apps",
                            x: 0.065, y: 0.04,
                            fontSize: 0.1, fontWeight: 800,
                            color: "#FFFFFF"
                        )
                    ],
                    devices: [
                        DeviceSlot(
                            screenshotFile: "screen1.png",
                            mockup: "iPhone 17 Pro Max",
                            x: 0.5, y: 0.6,
                            scale: 0.85
                        )
                    ]
                )
            ]
        )

        let data = try JSONEncoder().encode(plan)
        let decoded = try JSONDecoder().decode(CompositionPlan.self, from: data)

        #expect(decoded.appName == "TestApp")
        #expect(decoded.canvas.width == 1320)
        #expect(decoded.canvas.height == 2868)
        #expect(decoded.defaults.font == "Inter")
        #expect(decoded.screens.count == 1)
        #expect(decoded.screens[0].texts.count == 1)
        #expect(decoded.screens[0].texts[0].content == "All Your Apps")
        #expect(decoded.screens[0].texts[0].fontSize == 0.1)
        #expect(decoded.screens[0].devices.count == 1)
        #expect(decoded.screens[0].devices[0].mockup == "iPhone 17 Pro Max")
        #expect(decoded.screens[0].devices[0].scale == 0.85)
    }

    @Test func `device slot defaults rotation to 0 and contentMode to fit`() throws {
        let json = """
        {
            "screenshotFile": "screen.png",
            "mockup": "iPhone 17 Pro Max",
            "x": 0.5, "y": 0.6, "scale": 0.8
        }
        """
        let slot = try JSONDecoder().decode(DeviceSlot.self, from: Data(json.utf8))
        #expect(slot.rotation == 0)
        #expect(slot.contentMode == .fit)
    }

    @Test func `device slot with rotation and fill content mode`() throws {
        let json = """
        {
            "screenshotFile": "screen.png",
            "mockup": "iPhone 17 Pro Max",
            "x": 0.5, "y": 0.6, "scale": 0.8,
            "rotation": 6.5,
            "contentMode": "fill"
        }
        """
        let slot = try JSONDecoder().decode(DeviceSlot.self, from: Data(json.utf8))
        #expect(slot.rotation == 6.5)
        #expect(slot.contentMode == .fill)
    }

    @Test func `text overlay defaults fontWeight to 700 and font to nil`() throws {
        let json = """
        {
            "content": "Hello",
            "x": 0.1, "y": 0.1,
            "fontSize": 0.08,
            "color": "#FFF"
        }
        """
        let text = try JSONDecoder().decode(TextOverlay.self, from: Data(json.utf8))
        #expect(text.fontWeight == 700)
        #expect(text.font == nil)
    }

    @Test func `solid background encodes and decodes`() throws {
        let bg = SlideBackground.solid("#FF0000")
        let data = try JSONEncoder().encode(bg)
        let decoded = try JSONDecoder().decode(SlideBackground.self, from: data)
        #expect(decoded == bg)
    }

    @Test func `gradient background encodes and decodes`() throws {
        let bg = SlideBackground.gradient(from: "#000", to: "#FFF", angle: 135)
        let data = try JSONEncoder().encode(bg)
        let decoded = try JSONDecoder().decode(SlideBackground.self, from: data)
        #expect(decoded == bg)
    }

    @Test func `slide inherits defaults when background is nil`() throws {
        let plan = CompositionPlan(
            appName: "App",
            canvas: CanvasSize(width: 1320, height: 2868),
            defaults: SlideDefaults(
                background: .solid("#111"),
                textColor: "#FFF",
                subtextColor: "#888",
                accentColor: "#F00",
                font: "Inter"
            ),
            screens: [
                SlideComposition(texts: [], devices: [])
            ]
        )

        #expect(plan.screens[0].background == nil)
        // Command layer resolves nil → defaults.background
    }

    @Test func `slide can override background`() throws {
        let slide = SlideComposition(
            background: .gradient(from: "#000", to: "#333", angle: 180),
            texts: [],
            devices: []
        )
        if case .gradient(let from, _, _) = slide.background {
            #expect(from == "#000")
        } else {
            Issue.record("Expected gradient background")
        }
    }

    @Test func `multiple devices on one slide`() throws {
        let slide = SlideComposition(
            texts: [
                TextOverlay(content: "Cross Platform", x: 0.05, y: 0.05, fontSize: 0.09, color: "#FFF")
            ],
            devices: [
                DeviceSlot(screenshotFile: "iphone.png", mockup: "iPhone 17 Pro Max", x: 0.7, y: 0.6, scale: 0.7),
                DeviceSlot(screenshotFile: "ipad.png", mockup: "iPad Pro 13", x: 0.3, y: 0.55, scale: 0.5),
                DeviceSlot(screenshotFile: "watch.png", mockup: "Apple Watch Ultra", x: 0.15, y: 0.7, scale: 0.3, rotation: -10),
            ]
        )

        #expect(slide.devices.count == 3)
        #expect(slide.devices[2].rotation == -10)
    }

    @Test func `canvas size defaults displayType to nil`() throws {
        let json = """
        { "width": 1320, "height": 2868 }
        """
        let canvas = try JSONDecoder().decode(CanvasSize.self, from: Data(json.utf8))
        #expect(canvas.displayType == nil)
    }

    @Test func `full plan JSON round-trip with multiple screens`() throws {
        let json = """
        {
            "appName": "MyApp",
            "canvas": { "width": 1290, "height": 2796, "displayType": "APP_IPHONE_67" },
            "defaults": {
                "background": { "type": "solid", "color": "#0A1628" },
                "textColor": "#FFFFFF",
                "subtextColor": "#A8B8D0",
                "accentColor": "#4A7CFF",
                "font": "Inter"
            },
            "screens": [
                {
                    "texts": [
                        { "content": "Hero Screen", "x": 0.065, "y": 0.04, "fontSize": 0.1, "color": "#FFF" },
                        { "content": "Your best app ever", "x": 0.065, "y": 0.1, "fontSize": 0.035, "color": "#A8B8D0" }
                    ],
                    "devices": [
                        { "screenshotFile": "hero.png", "mockup": "iPhone 17 Pro Max", "x": 0.5, "y": 0.6, "scale": 0.85 }
                    ]
                },
                {
                    "background": { "type": "gradient", "from": "#1a2744", "to": "#0A1628", "angle": 180 },
                    "texts": [
                        { "content": "Multi Device", "x": 0.05, "y": 0.05, "fontSize": 0.09, "fontWeight": 800, "color": "#FFF" }
                    ],
                    "devices": [
                        { "screenshotFile": "phone.png", "mockup": "iPhone 17 Pro Max", "x": 0.7, "y": 0.55, "scale": 0.7, "rotation": 5 },
                        { "screenshotFile": "laptop.png", "mockup": "MacBook Pro M4 16-inch", "x": 0.3, "y": 0.65, "scale": 0.4 }
                    ]
                }
            ]
        }
        """

        let plan = try JSONDecoder().decode(CompositionPlan.self, from: Data(json.utf8))
        #expect(plan.appName == "MyApp")
        #expect(plan.canvas.displayType == "APP_IPHONE_67")
        #expect(plan.screens.count == 2)
        #expect(plan.screens[0].texts.count == 2)
        #expect(plan.screens[0].devices[0].scale == 0.85)
        #expect(plan.screens[1].devices.count == 2)
        #expect(plan.screens[1].devices[0].rotation == 5)
        if case .gradient(_, let to, let angle) = plan.screens[1].background {
            #expect(to == "#0A1628")
            #expect(angle == 180)
        } else {
            Issue.record("Expected gradient background on screen 1")
        }
    }
}
