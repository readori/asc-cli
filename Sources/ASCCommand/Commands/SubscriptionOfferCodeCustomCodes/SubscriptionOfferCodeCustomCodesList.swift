import ArgumentParser
import Domain

struct SubscriptionOfferCodeCustomCodesList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List custom codes for a subscription offer code"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Offer code ID")
    var offerCodeId: String

    func run() async throws {
        let repo = try ClientProvider.makeSubscriptionOfferCodeRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any SubscriptionOfferCodeRepository) async throws -> String {
        let items = try await repo.listCustomCodes(offerCodeId: offerCodeId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            items,
            headers: ["ID", "Custom Code", "Codes", "Expiration", "Active"],
            rowMapper: { [$0.id, $0.customCode, String($0.numberOfCodes), $0.expirationDate ?? "", String($0.isActive)] }
        )
    }
}
