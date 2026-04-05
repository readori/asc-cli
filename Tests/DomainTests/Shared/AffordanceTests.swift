import Foundation
import Testing
@testable import Domain

@Suite
struct AffordanceTests {

    // MARK: - CLI rendering

    @Test func `affordance renders CLI command with single param`() {
        let affordance = Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": "123"])
        #expect(affordance.cliCommand == "asc versions list --app-id 123")
    }

    @Test func `affordance renders CLI command with multiple params sorted by key`() {
        let affordance = Affordance(key: "test", command: "builds", action: "list", params: ["platform": "ios", "app-id": "42"])
        #expect(affordance.cliCommand == "asc builds list --app-id 42 --platform ios")
    }

    @Test func `affordance renders CLI command with no params`() {
        let affordance = Affordance(key: "listAll", command: "apps", action: "list", params: [:])
        #expect(affordance.cliCommand == "asc apps list")
    }

    // MARK: - REST rendering

    @Test func `affordance renders REST link for list action`() {
        let affordance = Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": "123"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps/123/versions")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for get action`() {
        let affordance = Affordance(key: "getVersion", command: "versions", action: "get", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for create action`() {
        let affordance = Affordance(key: "createVersion", command: "versions", action: "create", params: ["app-id": "123"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps/123/versions")
        #expect(link.method == "POST")
    }

    @Test func `affordance renders REST link for update action`() {
        let affordance = Affordance(key: "updateVersion", command: "versions", action: "update", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1")
        #expect(link.method == "PATCH")
    }

    @Test func `affordance renders REST link for delete action`() {
        let affordance = Affordance(key: "deleteVersion", command: "versions", action: "delete", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1")
        #expect(link.method == "DELETE")
    }

    @Test func `affordance renders REST link for submit action as POST`() {
        let affordance = Affordance(key: "submitForReview", command: "versions", action: "submit", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1/submit")
        #expect(link.method == "POST")
    }

    @Test func `affordance renders REST link for top-level list with no parent`() {
        let affordance = Affordance(key: "listApps", command: "apps", action: "list", params: [:])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps")
        #expect(link.method == "GET")
    }

    // MARK: - APILink encoding

    @Test func `APILink encodes to JSON with href and method`() throws {
        let link = APILink(href: "/api/v1/apps", method: "GET")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(link)
        let decoded = try JSONDecoder().decode(APILink.self, from: data)
        #expect(decoded.href == "/api/v1/apps")
        #expect(decoded.method == "GET")
    }

    // MARK: - AffordanceMode

    @Test func `AffordanceMode has cli and rest cases`() {
        let cli = AffordanceMode.cli
        let rest = AffordanceMode.rest
        #expect(cli != rest)
    }

    // MARK: - Structured affordances derive CLI affordances

    @Test func `structuredAffordances derive affordances dictionary`() {
        struct TestModel: AffordanceProviding {
            var structuredAffordances: [Affordance] {
                [
                    Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": "123"]),
                    Affordance(key: "listBuilds", command: "builds", action: "list", params: ["app-id": "123"]),
                ]
            }
        }
        let model = TestModel()
        #expect(model.affordances["listVersions"] == "asc versions list --app-id 123")
        #expect(model.affordances["listBuilds"] == "asc builds list --app-id 123")
    }

    @Test func `structuredAffordances derive apiLinks dictionary`() {
        struct TestModel: AffordanceProviding {
            var structuredAffordances: [Affordance] {
                [
                    Affordance(key: "listVersions", command: "versions", action: "list", params: ["app-id": "123"]),
                ]
            }
        }
        let model = TestModel()
        #expect(model.apiLinks["listVersions"]?.href == "/api/v1/apps/123/versions")
        #expect(model.apiLinks["listVersions"]?.method == "GET")
    }

    // MARK: - App model affordances (migrated to structured)

    @Test func `App affordances render as CLI commands`() {
        let app = App(id: "42", name: "MyApp", bundleId: "com.test")
        #expect(app.affordances["listVersions"] == "asc versions list --app-id 42")
        #expect(app.affordances["listAppInfos"] == "asc app-infos list --app-id 42")
        #expect(app.affordances["listReviews"] == "asc reviews list --app-id 42")
    }

    @Test func `App apiLinks render as REST links`() {
        let app = App(id: "42", name: "MyApp", bundleId: "com.test")
        #expect(app.apiLinks["listVersions"]?.href == "/api/v1/apps/42/versions")
        #expect(app.apiLinks["listVersions"]?.method == "GET")
        #expect(app.apiLinks["listAppInfos"]?.href == "/api/v1/apps/42/app-infos")
        #expect(app.apiLinks["listReviews"]?.href == "/api/v1/apps/42/reviews")
    }

    @Test func `AppStoreVersion affordances render as CLI commands`() {
        let version = AppStoreVersion(id: "v-1", appId: "42", versionString: "1.0", platform: .iOS, state: .prepareForSubmission)
        #expect(version.affordances["listLocalizations"] == "asc version-localizations list --version-id v-1")
        #expect(version.affordances["listVersions"] == "asc versions list --app-id 42")
        #expect(version.affordances["checkReadiness"] == "asc versions check-readiness --version-id v-1")
        #expect(version.affordances["submitForReview"] == "asc versions submit --version-id v-1")
    }

    @Test func `AppStoreVersion apiLinks render as REST links`() {
        let version = AppStoreVersion(id: "v-1", appId: "42", versionString: "1.0", platform: .iOS, state: .prepareForSubmission)
        #expect(version.apiLinks["listLocalizations"]?.href == "/api/v1/versions/v-1/localizations")
        #expect(version.apiLinks["listVersions"]?.href == "/api/v1/apps/42/versions")
        #expect(version.apiLinks["checkReadiness"]?.href == "/api/v1/versions/v-1/check-readiness")
        #expect(version.apiLinks["submitForReview"]?.href == "/api/v1/versions/v-1/submit")
    }

    @Test func `AppStoreVersion submit affordance only when editable`() {
        let editable = AppStoreVersion(id: "v-1", appId: "42", versionString: "1.0", platform: .iOS, state: .prepareForSubmission)
        let live = AppStoreVersion(id: "v-2", appId: "42", versionString: "1.0", platform: .iOS, state: .readyForSale)
        #expect(editable.affordances["submitForReview"] != nil)
        #expect(live.affordances["submitForReview"] == nil)
    }

    // MARK: - Nested resource paths

    @Test func `affordance renders REST link for version localizations`() {
        let affordance = Affordance(key: "listLocalizations", command: "version-localizations", action: "list", params: ["version-id": "v-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/versions/v-1/localizations")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for screenshot sets`() {
        let affordance = Affordance(key: "listScreenshotSets", command: "screenshot-sets", action: "list", params: ["localization-id": "loc-1"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/version-localizations/loc-1/screenshot-sets")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for builds under app`() {
        let affordance = Affordance(key: "listBuilds", command: "builds", action: "list", params: ["app-id": "123"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps/123/builds")
        #expect(link.method == "GET")
    }

    @Test func `affordance renders REST link for reviews under app`() {
        let affordance = Affordance(key: "listReviews", command: "reviews", action: "list", params: ["app-id": "123"])
        let link = affordance.restLink
        #expect(link.href == "/api/v1/apps/123/reviews")
        #expect(link.method == "GET")
    }
}