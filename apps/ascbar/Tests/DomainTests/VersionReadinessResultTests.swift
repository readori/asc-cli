import Testing
@testable import Domain

@Suite("VersionReadinessResult")
struct VersionReadinessResultTests {

    // MARK: - VersionReadinessResult

    @Test func `isReadyToSubmit false when mustFix non-empty`() {
        let result = VersionReadinessResult(
            versionId: "v1",
            versionString: "2.1.0",
            isReadyToSubmit: false,
            buildLabel: nil,
            mustFix: [ReadinessItem(id: "build", title: "Build Attached", description: "No build attached")],
            shouldFix: [],
            passing: []
        )
        #expect(result.isReadyToSubmit == false)
        #expect(!result.mustFix.isEmpty)
    }

    @Test func `isReadyToSubmit true when mustFix empty`() {
        let result = VersionReadinessResult(
            versionId: "v1",
            versionString: "2.1.0",
            isReadyToSubmit: true,
            buildLabel: "2.1.0 (102)",
            mustFix: [],
            shouldFix: [],
            passing: [ReadinessItem(id: "state", title: "Version State", description: "Editable")]
        )
        #expect(result.isReadyToSubmit == true)
        #expect(result.mustFix.isEmpty)
        #expect(result.buildLabel == "2.1.0 (102)")
    }

    @Test func `shouldFix item can have navigateToLocalizations fixAction`() {
        let item = ReadinessItem(
            id: "whatsNew",
            title: "What's New Text",
            description: "Missing in: en-US",
            fixAction: .navigateToLocalizations
        )
        #expect(item.fixAction == .navigateToLocalizations)
        #expect(item.title == "What's New Text")
        #expect(item.description == "Missing in: en-US")
    }

    @Test func `mustFix item can have copyCommand fixAction`() {
        let cmd = "asc builds list --app-id app1"
        let item = ReadinessItem(
            id: "build",
            title: "Build Attached",
            description: "No build attached",
            fixAction: .copyCommand(cmd)
        )
        #expect(item.fixAction == .copyCommand(cmd))
    }

    @Test func `ReadinessItem with no fixAction is nil`() {
        let item = ReadinessItem(id: "pricing", title: "Pricing", description: "Configured")
        #expect(item.fixAction == nil)
    }

    @Test func `VersionReadinessResult buildLabel is nil when no build`() {
        let result = VersionReadinessResult(
            versionId: "v1",
            versionString: "1.0.0",
            isReadyToSubmit: false,
            buildLabel: nil,
            mustFix: [ReadinessItem(id: "build", title: "Build", description: "No build")],
            shouldFix: [],
            passing: []
        )
        #expect(result.buildLabel == nil)
    }
}

@Suite("LocalizationSummary")
struct LocalizationSummaryTests {

    @Test func `isPrimary is true for primary locale`() {
        let loc = LocalizationSummary(id: "l1", locale: "en-US", isPrimary: true, whatsNew: "Bug fixes")
        #expect(loc.isPrimary == true)
    }

    @Test func `isPrimary is false for secondary locale`() {
        let loc = LocalizationSummary(id: "l2", locale: "zh-Hans", isPrimary: false)
        #expect(loc.isPrimary == false)
    }

    @Test func `model preserves whatsNew text correctly`() {
        let text = "New dark mode and performance improvements"
        let loc = LocalizationSummary(id: "l1", locale: "en-US", isPrimary: true, whatsNew: text)
        #expect(loc.whatsNew == text)
    }

    @Test func `whatsNew is nil when missing`() {
        let loc = LocalizationSummary(id: "l1", locale: "en-US", isPrimary: true)
        #expect(loc.whatsNew == nil)
    }

    @Test func `locale is preserved correctly`() {
        let loc = LocalizationSummary(id: "l1", locale: "ja", isPrimary: false)
        #expect(loc.locale == "ja")
    }

    @Test func `setFieldCount counts non-empty fields`() {
        let loc = LocalizationSummary(id: "l1", locale: "en-US", isPrimary: true,
                                      whatsNew: "Bug fixes", description: "An app",
                                      keywords: "test")
        #expect(loc.setFieldCount == 3)
    }

    @Test func `setFieldCount is zero when all fields nil`() {
        let loc = LocalizationSummary(id: "l1", locale: "en-US", isPrimary: true)
        #expect(loc.setFieldCount == 0)
    }
}
