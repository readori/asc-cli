import Testing
@testable import ASCCommand

@Suite
struct AppShotsDisplayTypeTests {

    // MARK: - Required iPhone sizes

    @Test func `iphone69 dimensions are 1320 by 2868`() {
        let t = AppShotsDisplayType.iphone69
        #expect(t.dimensions.width == 1320)
        #expect(t.dimensions.height == 2868)
    }

    @Test func `iphone67 dimensions are 1290 by 2796`() {
        let t = AppShotsDisplayType.iphone67
        #expect(t.dimensions.width == 1290)
        #expect(t.dimensions.height == 2796)
    }

    // MARK: - Optional iPhone sizes

    @Test func `iphone65 dimensions are 1260 by 2736`() {
        let t = AppShotsDisplayType.iphone65
        #expect(t.dimensions.width == 1260)
        #expect(t.dimensions.height == 2736)
    }

    @Test func `iphone55 dimensions are 1242 by 2208`() {
        let t = AppShotsDisplayType.iphone55
        #expect(t.dimensions.width == 1242)
        #expect(t.dimensions.height == 2208)
    }

    @Test func `iphone47 dimensions are 750 by 1334`() {
        let t = AppShotsDisplayType.iphone47
        #expect(t.dimensions.width == 750)
        #expect(t.dimensions.height == 1334)
    }

    // MARK: - iPad sizes

    @Test func `ipadPro129 dimensions are 2048 by 2732`() {
        let t = AppShotsDisplayType.ipadPro129
        #expect(t.dimensions.width == 2048)
        #expect(t.dimensions.height == 2732)
    }

    @Test func `ipadPro3Gen11 dimensions are 1668 by 2388`() {
        let t = AppShotsDisplayType.ipadPro3Gen11
        #expect(t.dimensions.width == 1668)
        #expect(t.dimensions.height == 2388)
    }

    // MARK: - Other platforms

    @Test func `appleTv dimensions are 1920 by 1080`() {
        let t = AppShotsDisplayType.appleTv
        #expect(t.dimensions.width == 1920)
        #expect(t.dimensions.height == 1080)
    }

    @Test func `desktop dimensions are 2560 by 1600`() {
        let t = AppShotsDisplayType.desktop
        #expect(t.dimensions.width == 2560)
        #expect(t.dimensions.height == 1600)
    }

    @Test func `appleVisionPro dimensions are 3840 by 2160`() {
        let t = AppShotsDisplayType.appleVisionPro
        #expect(t.dimensions.width == 3840)
        #expect(t.dimensions.height == 2160)
    }

    // MARK: - Raw value parsing (ExpressibleByArgument)

    @Test func `parses APP_IPHONE_69 from raw value string`() {
        #expect(AppShotsDisplayType(rawValue: "APP_IPHONE_69") == .iphone69)
    }

    @Test func `parses APP_IPAD_PRO_129 from raw value string`() {
        #expect(AppShotsDisplayType(rawValue: "APP_IPAD_PRO_129") == .ipadPro129)
    }

    @Test func `parses APP_APPLE_VISION_PRO from raw value string`() {
        #expect(AppShotsDisplayType(rawValue: "APP_APPLE_VISION_PRO") == .appleVisionPro)
    }

    @Test func `returns nil for unknown raw value`() {
        #expect(AppShotsDisplayType(rawValue: "UNKNOWN_DEVICE") == nil)
    }

    @Test func `all 16 cases have non-zero dimensions`() {
        for type in AppShotsDisplayType.allCases {
            #expect(type.dimensions.width > 0)
            #expect(type.dimensions.height > 0)
        }
    }
}
