import ArgumentParser

struct AnalyticsReportsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analytics-reports",
        abstract: "Manage analytics reports",
        subcommands: [
            AnalyticsReportsRequest.self,
            AnalyticsReportsList.self,
            AnalyticsReportsDelete.self,
            AnalyticsReportsReportsList.self,
            AnalyticsReportsInstancesList.self,
            AnalyticsReportsSegmentsList.self,
        ]
    )
}
