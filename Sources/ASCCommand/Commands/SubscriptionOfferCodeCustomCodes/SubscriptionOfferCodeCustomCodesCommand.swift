import ArgumentParser

struct SubscriptionOfferCodeCustomCodesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subscription-offer-code-custom-codes",
        abstract: "Manage subscription offer code custom codes",
        subcommands: [
            SubscriptionOfferCodeCustomCodesList.self,
            SubscriptionOfferCodeCustomCodesCreate.self,
            SubscriptionOfferCodeCustomCodesUpdate.self,
        ]
    )
}
