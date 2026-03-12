import ArgumentParser
import Domain

struct SubscriptionOfferCodeOneTimeCodesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create one-time use codes for a subscription offer code"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Offer code ID")
    var offerCodeId: String

    @Option(name: .long, help: "Number of codes to generate")
    var numberOfCodes: Int

    @Option(name: .long, help: "Expiration date in YYYY-MM-DD format")
    var expirationDate: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionOfferCodeRepository) async throws -> String {
        let item = try await repo.createOneTimeUseCode(
            offerCodeId: offerCodeId,
            numberOfCodes: numberOfCodes,
            expirationDate: expirationDate
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Codes", "Expiration", "Active"],
            rowMapper: { [$0.id, String($0.numberOfCodes), $0.expirationDate ?? "", String($0.isActive)] }
        )
    }
}
