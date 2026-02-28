import Foundation
import Testing
@testable import Infrastructure
@testable import Domain

// MARK: - Stub HTTP client

final class StubHTTPClient: HTTPPerforming, @unchecked Sendable {
    var response: (Data, URLResponse)?
    var error: Error?
    private(set) var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let error { throw error }
        return response!
    }
}

private func makeHTTPResponse(statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://generativelanguage.googleapis.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}

/// Fake PNG bytes (valid PNG magic bytes so size check passes)
private let fakePNGData: Data = {
    var bytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    bytes += [UInt8](repeating: 0x00, count: 200)
    return Data(bytes)
}()

private func makeGeminiImageResponse(imageData: Data = fakePNGData) -> Data {
    let base64 = imageData.base64EncodedString()
    let body = """
    {
      "choices": [
        {
          "message": {
            "content": [
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/png;base64,\(base64)"
                }
              }
            ]
          }
        }
      ]
    }
    """
    return body.data(using: .utf8)!
}

private func makeSingleScreenPlan(imagePrompt: String = "Clean UI on dark background") -> ScreenPlan {
    ScreenPlan(
        appId: "app-123",
        appName: "TestApp",
        tagline: "Great app",
        tone: .professional,
        colors: ScreenColors(primary: "#000000", accent: "#FF0000", text: "#FFFFFF", subtext: "#CCCCCC"),
        screens: [
            ScreenConfig(
                index: 0,
                screenshotFile: "screen1.png",
                heading: "Work Smarter",
                subheading: "Organize your tasks",
                layoutMode: .center,
                visualDirection: "Main dashboard",
                imagePrompt: imagePrompt
            )
        ]
    )
}

// MARK: - Tests

@Suite
struct GeminiScreenshotGenerationRepositoryTests {

    @Test func `generateImages returns PNG data for each screen`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(apiKey: "test-key", httpClient: stub)
        let results = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [])

        #expect(results.count == 1)
        #expect(results[0] != nil)
        #expect(results[0]!.count > 100)
    }

    @Test func `generateImages sends Authorization Bearer header`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(apiKey: "my-api-key", httpClient: stub)
        _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [])

        #expect(stub.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer my-api-key")
    }

    @Test func `generateImages sends POST to correct endpoint`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(
            apiKey: "test-key",
            baseURL: "https://generativelanguage.googleapis.com/v1beta/openai",
            httpClient: stub
        )
        _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [])

        #expect(stub.lastRequest?.url?.absoluteString == "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")
        #expect(stub.lastRequest?.httpMethod == "POST")
    }

    @Test func `generateImages includes imagePrompt in request body`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(apiKey: "key", httpClient: stub)
        _ = try await repo.generateImages(
            plan: makeSingleScreenPlan(imagePrompt: "Dark navy with glowing accents"),
            screenshotURLs: []
        )

        let bodyData = stub.lastRequest?.httpBody ?? Data()
        let bodyString = String(data: bodyData, encoding: .utf8) ?? ""
        #expect(bodyString.contains("Dark navy with glowing accents"))
    }

    @Test func `generateImages uses custom model in request body`() async throws {
        let stub = StubHTTPClient()
        stub.response = (makeGeminiImageResponse(), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(
            apiKey: "key",
            model: "gemini-2.0-flash-preview-image-generation",
            httpClient: stub
        )
        _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [])

        let bodyData = stub.lastRequest?.httpBody ?? Data()
        let bodyJSON = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        #expect(bodyJSON?["model"] as? String == "gemini-2.0-flash-preview-image-generation")
    }

    @Test func `generateImages throws on HTTP error`() async throws {
        let stub = StubHTTPClient()
        stub.response = ("Unauthorized".data(using: .utf8)!, makeHTTPResponse(statusCode: 401))

        let repo = GeminiScreenshotGenerationRepository(apiKey: "bad-key", httpClient: stub)
        do {
            _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [])
            Issue.record("Expected error to be thrown")
        } catch let error as Domain.APIError {
            if case .unknown(let msg) = error {
                #expect(msg.contains("401"))
            } else {
                Issue.record("Expected APIError.unknown, got \(error)")
            }
        }
    }

    @Test func `generateImages throws when no image data in response`() async throws {
        let stub = StubHTTPClient()
        stub.response = (Data("{\"choices\":[{\"message\":{\"content\":\"no image here\"}}]}".utf8), makeHTTPResponse())

        let repo = GeminiScreenshotGenerationRepository(apiKey: "key", httpClient: stub)
        do {
            _ = try await repo.generateImages(plan: makeSingleScreenPlan(), screenshotURLs: [])
            Issue.record("Expected error to be thrown")
        } catch let error as Domain.APIError {
            if case .unknown(let msg) = error {
                #expect(msg.contains("No image data found"))
            } else {
                Issue.record("Expected APIError.unknown, got \(error)")
            }
        }
    }

    @Test func `generateImages returns empty dict for plan with no screens`() async throws {
        let stub = StubHTTPClient()
        let emptyPlan = ScreenPlan(
            appId: "app-1", appName: "App", tagline: "t", tone: .minimal,
            colors: ScreenColors(primary: "#000", accent: "#fff", text: "#fff", subtext: "#ccc"),
            screens: []
        )

        let repo = GeminiScreenshotGenerationRepository(apiKey: "key", httpClient: stub)
        let results = try await repo.generateImages(plan: emptyPlan, screenshotURLs: [])

        #expect(results.isEmpty)
    }
}
