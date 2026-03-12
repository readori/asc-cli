@preconcurrency import AppStoreConnect_Swift_SDK
import Testing
@testable import Infrastructure
@testable import Domain

@Suite
struct SDKPerfMetricsRepositoryTests {

    private func makeXcodeMetrics(
        platform: String = "IOS",
        categoryIdentifier: AppStoreConnect_Swift_SDK.MetricCategory = .launch,
        metricIdentifier: String = "launchTime",
        unitIdentifier: String = "s",
        unitDisplayName: String = "Seconds",
        pointVersion: String = "2.0",
        pointValue: Double = 1.5,
        goalValue: Double = 1.0
    ) -> XcodeMetrics {
        XcodeMetrics(
            version: "1.0",
            insights: nil,
            productData: [
                .init(
                    platform: platform,
                    metricCategories: [
                        .init(
                            identifier: categoryIdentifier,
                            metrics: [
                                .init(
                                    identifier: metricIdentifier,
                                    goalKeys: nil,
                                    unit: .init(identifier: unitIdentifier, displayName: unitDisplayName),
                                    datasets: [
                                        .init(
                                            filterCriteria: nil,
                                            points: [.init(version: pointVersion, value: pointValue)],
                                            recommendedMetricGoal: .init(value: goalValue)
                                        )
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ]
        )
    }

    @Test func `listAppMetrics flattens XcodeMetrics into PerfPowerMetric`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics())

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

        #expect(result.count == 1)
        #expect(result[0].parentId == "app-1")
        #expect(result[0].parentType == .app)
        #expect(result[0].platform == "IOS")
        #expect(result[0].category == PerformanceMetricCategory.launch)
        #expect(result[0].metricIdentifier == "launchTime")
        #expect(result[0].unit == "s")
        #expect(result[0].latestValue == 1.5)
        #expect(result[0].latestVersion == "2.0")
        #expect(result[0].goalValue == 1.0)
    }

    @Test func `listAppMetrics injects appId into each metric`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics())

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-42", metricType: nil)

        #expect(result.allSatisfy { $0.parentId == "app-42" })
        #expect(result.allSatisfy { $0.parentType == .app })
    }

    @Test func `listBuildMetrics injects buildId with build parent type`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics())

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listBuildMetrics(buildId: "build-7", metricType: nil)

        #expect(result.allSatisfy { $0.parentId == "build-7" })
        #expect(result.allSatisfy { $0.parentType == .build })
    }

    @Test func `listAppMetrics generates synthetic id from parent, category, and metric`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(makeXcodeMetrics(
            categoryIdentifier: AppStoreConnect_Swift_SDK.MetricCategory.memory,
            metricIdentifier: "peakMemory"
        ))

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

        #expect(result[0].id == "app-1-MEMORY-peakMemory")
    }

    @Test func `listAppMetrics returns empty when no productData`() async throws {
        let stub = StubAPIClient()
        stub.willReturn(XcodeMetrics(version: "1.0", insights: nil, productData: nil))

        let repo = SDKPerfMetricsRepository(client: stub)
        let result = try await repo.listAppMetrics(appId: "app-1", metricType: nil)

        #expect(result.isEmpty)
    }
}
