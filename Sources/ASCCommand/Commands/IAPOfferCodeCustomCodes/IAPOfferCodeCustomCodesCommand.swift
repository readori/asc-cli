import ArgumentParser

struct IAPOfferCodeCustomCodesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "iap-offer-code-custom-codes",
        abstract: "Manage in-app purchase offer code custom codes",
        subcommands: [
            IAPOfferCodeCustomCodesList.self,
            IAPOfferCodeCustomCodesCreate.self,
            IAPOfferCodeCustomCodesUpdate.self,
        ]
    )
}
