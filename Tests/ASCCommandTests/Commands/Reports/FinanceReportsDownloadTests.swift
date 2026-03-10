import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct FinanceReportsDownloadTests {

    @Test func `downloads finance report and outputs JSON with row data`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadFinanceReport(
            vendorNumber: .any,
            reportType: .any,
            regionCode: .any,
            reportDate: .any
        ).willReturn([
            ["Region": "US", "Units": "100", "Proceeds": "699.00"]
        ])

        let cmd = try FinanceReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "FINANCIAL",
            "--region-code", "US",
            "--report-date", "2024-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "Proceeds" : "699.00",
              "Region" : "US",
              "Units" : "100"
            }
          ]
        }
        """)
    }

    @Test func `table output includes row values`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadFinanceReport(
            vendorNumber: .any,
            reportType: .any,
            regionCode: .any,
            reportDate: .any
        ).willReturn([
            ["Region": "US", "Units": "100", "Proceeds": "699.00"]
        ])

        let cmd = try FinanceReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "FINANCIAL",
            "--region-code", "US",
            "--report-date", "2024-01",
            "--output", "table",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("US"))
        #expect(output.contains("100"))
        #expect(output.contains("699.00"))
    }
}
