import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SalesReportsDownloadTests {

    @Test func `downloads sales report and outputs JSON with row data`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any
        ).willReturn([
            ["Provider": "APPLE", "SKU": "com.example", "Units": "10"]
        ])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "Provider" : "APPLE",
              "SKU" : "com.example",
              "Units" : "10"
            }
          ]
        }
        """)
    }

    @Test func `downloads sales report with report date`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any
        ).willReturn([
            ["Provider": "APPLE", "SKU": "com.a", "Units": "5"]
        ])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "MONTHLY",
            "--report-date", "2024-01",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "Provider" : "APPLE",
              "SKU" : "com.a",
              "Units" : "5"
            }
          ]
        }
        """)
    }

    @Test func `table output includes row values`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any
        ).willReturn([
            ["Provider": "APPLE", "SKU": "com.example", "Units": "10"]
        ])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
            "--output", "table",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("APPLE"))
        #expect(output.contains("com.example"))
        #expect(output.contains("10"))
    }

    @Test func `handles empty report`() async throws {
        let mockRepo = MockReportRepository()
        given(mockRepo).downloadSalesReport(
            vendorNumber: .any,
            reportType: .any,
            subType: .any,
            frequency: .any,
            reportDate: .any
        ).willReturn([])

        let cmd = try SalesReportsDownload.parse([
            "--vendor-number", "123",
            "--report-type", "SALES",
            "--sub-type", "SUMMARY",
            "--frequency", "DAILY",
            "--pretty",
        ])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [

          ]
        }
        """)
    }
}
