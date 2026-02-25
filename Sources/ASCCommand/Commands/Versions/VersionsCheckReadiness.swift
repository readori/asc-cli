import ArgumentParser
import Domain

struct VersionsCheckReadiness: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check-readiness",
        abstract: "Pre-flight check for App Store submission readiness"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App Store Version ID")
    var versionId: String

    func run() async throws {
        let versionRepo = try ClientProvider.makeVersionRepository()
        let buildRepo = try ClientProvider.makeBuildRepository()
        let reviewDetailRepo = try ClientProvider.makeReviewDetailRepository()
        let localizationRepo = try ClientProvider.makeVersionLocalizationRepository()
        let screenshotRepo = try ClientProvider.makeScreenshotRepository()
        let pricingRepo = try ClientProvider.makePricingRepository()
        print(try await execute(
            versionRepo: versionRepo,
            buildRepo: buildRepo,
            reviewDetailRepo: reviewDetailRepo,
            localizationRepo: localizationRepo,
            screenshotRepo: screenshotRepo,
            pricingRepo: pricingRepo
        ))
    }

    func execute(
        versionRepo: any VersionRepository,
        buildRepo: any BuildRepository,
        reviewDetailRepo: any ReviewDetailRepository,
        localizationRepo: any VersionLocalizationRepository,
        screenshotRepo: any ScreenshotRepository,
        pricingRepo: any PricingRepository
    ) async throws -> String {
        // 1. Fetch version (includes appId + buildId)
        let version = try await versionRepo.getVersion(id: versionId)

        // 2. State check (MUST FIX)
        let stateCheck: ReadinessCheck = version.isEditable
            ? .pass()
            : .fail("Version state '\(version.state.rawValue)' is not editable")

        // 3. Build check (MUST FIX)
        let buildCheck: BuildReadinessCheck
        if let buildId = version.buildId {
            let build = try await buildRepo.getBuild(id: buildId)
            let buildVersion: String
            if let num = build.buildNumber {
                buildVersion = "\(build.version) (\(num))"
            } else {
                buildVersion = build.version
            }
            buildCheck = BuildReadinessCheck(
                linked: true,
                valid: build.processingState == .valid,
                notExpired: !build.expired,
                buildVersion: buildVersion
            )
        } else {
            buildCheck = BuildReadinessCheck(linked: false, valid: false, notExpired: false)
        }

        // 4. Pricing check (MUST FIX)
        let hasPricing = try await pricingRepo.hasPricing(appId: version.appId)
        let pricingCheck: ReadinessCheck = hasPricing
            ? .pass()
            : .fail("No price schedule configured for this app")

        // 5. Review contact check (SHOULD FIX)
        let reviewDetail = try await reviewDetailRepo.getReviewDetail(versionId: versionId)
        let reviewContactCheck: ReadinessCheck = reviewDetail.hasContact
            ? .pass()
            : .fail("No contact email or phone set in App Store review information")

        // 6. Localization readiness
        let localizations = try await localizationRepo.listLocalizations(versionId: versionId)
        var localizationReadiness: [LocalizationReadiness] = []
        for loc in localizations {
            let sets = try await screenshotRepo.listScreenshotSets(localizationId: loc.id)
            let screenshotSetCount = sets.filter { $0.screenshotsCount > 0 }.count
            localizationReadiness.append(LocalizationReadiness(
                locale: loc.locale,
                hasDescription: loc.description != nil,
                hasKeywords: loc.keywords != nil,
                hasSupportUrl: loc.supportUrl != nil,
                hasWhatsNew: loc.whatsNew != nil,
                screenshotSetCount: screenshotSetCount
            ))
        }

        // 7. Aggregate MUST FIX result
        let isReadyToSubmit = stateCheck.pass && buildCheck.pass && pricingCheck.pass

        let readiness = VersionReadiness(
            id: version.id,
            appId: version.appId,
            versionString: version.versionString,
            state: version.state,
            isReadyToSubmit: isReadyToSubmit,
            stateCheck: stateCheck,
            buildCheck: buildCheck,
            pricingCheck: pricingCheck,
            reviewContactCheck: reviewContactCheck,
            localizations: localizationReadiness
        )

        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [readiness],
            headers: ["ID", "Version", "State", "Ready"],
            rowMapper: { [$0.id, $0.versionString, $0.state.displayName, $0.isReadyToSubmit ? "yes" : "no"] }
        )
    }
}
