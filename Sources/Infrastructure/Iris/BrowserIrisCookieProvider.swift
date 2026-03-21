import Domain
import Foundation
import SweetCookieKit

/// Resolves iris session cookies from browser cookie stores or environment.
///
/// Resolution order:
/// 1. `ASC_IRIS_COOKIES` environment variable (for CI/CD)
/// 2. Browser cookies from Chrome/Safari/Firefox (via SweetCookieKit)
public struct BrowserIrisCookieProvider: IrisCookieProvider {
    public init() {}

    public func resolveSession() throws -> IrisSession {
        // 1. Check environment variable
        if let envCookies = ProcessInfo.processInfo.environment["ASC_IRIS_COOKIES"],
           !envCookies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return IrisSession(cookies: envCookies)
        }

        // 2. Try extracting from browser cookies
        if let browserCookies = fetchFromBrowser() {
            return IrisSession(cookies: browserCookies)
        }

        throw IrisCookieError.noCookiesFound
    }

    private func fetchFromBrowser() -> String? {
        let cookieClient = BrowserCookieClient()
        let query = BrowserCookieQuery(
            domains: ["appstoreconnect.apple.com"],
            domainMatch: .suffix,
            includeExpired: false
        )

        // Key cookies needed for iris API
        let requiredCookieNames: Set<String> = ["myacinfo"]

        for browser in Browser.allCases {
            do {
                let storeRecords = try cookieClient.records(matching: query, in: browser)
                var cookiePairs: [String] = []
                var foundRequired = false

                for storeRecord in storeRecords {
                    for record in storeRecord.records {
                        cookiePairs.append("\(record.name)=\(record.value)")
                        if requiredCookieNames.contains(record.name) {
                            foundRequired = true
                        }
                    }
                }

                if foundRequired && !cookiePairs.isEmpty {
                    return cookiePairs.joined(separator: "; ")
                }
            } catch {
                continue
            }
        }
        return nil
    }
}

/// Errors specific to iris cookie resolution.
public enum IrisCookieError: LocalizedError {
    case noCookiesFound

    public var errorDescription: String? {
        switch self {
        case .noCookiesFound:
            "No App Store Connect cookies found. Log in to appstoreconnect.apple.com in your browser, or set ASC_IRIS_COOKIES environment variable."
        }
    }
}
