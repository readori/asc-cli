import Domain
import Foundation

// MARK: - HTTP abstraction for testability

public protocol HTTPPerforming: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPPerforming {}

// MARK: - GeminiScreenshotGenerationRepository

/// Calls the Gemini image generation API (OpenAI-compatible endpoint) for each screen
/// in the plan, sending the screen's `imagePrompt` + the matched screenshot.
/// Returns a dictionary mapping screen index → generated PNG data.
public struct GeminiScreenshotGenerationRepository: ScreenshotGenerationRepository {
    private let apiKey: String
    private let model: String
    private let baseURL: String
    private let httpClient: any HTTPPerforming

    public init(
        apiKey: String,
        model: String = "gemini-2.0-flash-preview-image-generation",
        baseURL: String = "https://generativelanguage.googleapis.com/v1beta/openai",
        httpClient: (any HTTPPerforming)? = nil
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.httpClient = httpClient ?? URLSession.shared
    }

    public func generateImages(plan: ScreenPlan, screenshotURLs: [URL]) async throws -> [Int: Data] {
        try await withThrowingTaskGroup(of: (Int, Data).self) { group in
            for screen in plan.screens {
                // Match screenshot by filename or fall back to index order
                let screenshotURL: URL? = screenshotURLs.first {
                    $0.lastPathComponent == screen.screenshotFile
                } ?? (screen.index < screenshotURLs.count ? screenshotURLs[screen.index] : nil)

                let prompt = screen.imagePrompt
                let index = screen.index

                group.addTask {
                    let imageData = try await self.generateSingleImage(
                        prompt: prompt,
                        screenshotURL: screenshotURL
                    )
                    return (index, imageData)
                }
            }

            var results: [Int: Data] = [:]
            for try await (index, data) in group {
                results[index] = data
            }
            return results
        }
    }

    // MARK: - Single image generation

    private func generateSingleImage(prompt: String, screenshotURL: URL?) async throws -> Data {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try buildRequestBody(prompt: prompt, screenshotURL: screenshotURL)

        let (data, response) = try await httpClient.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response type")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.unknown("Gemini API error \(httpResponse.statusCode): \(body)")
        }

        return try extractImageData(from: data)
    }

    // MARK: - Request building

    private func buildRequestBody(prompt: String, screenshotURL: URL?) throws -> Data {
        var messageContent: [[String: Any]] = []

        // Include screenshot as base64 image if available
        if let url = screenshotURL, let imageData = try? Data(contentsOf: url) {
            let base64 = imageData.base64EncodedString()
            let ext = url.pathExtension.lowercased()
            let mimeType = (ext == "jpg" || ext == "jpeg") ? "image/jpeg" : "image/png"
            messageContent.append([
                "type": "image_url",
                "image_url": ["url": "data:\(mimeType);base64,\(base64)"]
            ])
        }

        messageContent.append(["type": "text", "text": prompt])

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": [
                ["role": "user", "content": messageContent]
            ]
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }

    // MARK: - Response parsing — extract PNG from Gemini image generation response

    private func extractImageData(from responseData: Data) throws -> Data {
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            throw APIError.unknown("Response is not valid JSON")
        }

        // Check for API-level error
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw APIError.unknown("Gemini error: \(message)")
        }

        // OpenAI Chat Completions: choices[0].message.content (array of parts)
        if let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: Any] {

            if let contentArray = message["content"] as? [[String: Any]] {
                for part in contentArray {
                    if let data = extractImageFromPart(part) { return data }
                }
                // Fallback: base64 text in text parts
                for part in contentArray {
                    if (part["type"] as? String) == "text",
                       let text = part["text"] as? String,
                       let data = decodeBase64Image(text) { return data }
                }
            } else if let contentString = message["content"] as? String,
                      let data = decodeBase64Image(contentString) {
                return data
            }
        }

        // OpenAI Images API: data[0].b64_json
        if let dataArray = json["data"] as? [[String: Any]] {
            for item in dataArray {
                if let b64 = item["b64_json"] as? String,
                   let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
                   data.count > 100 { return data }
            }
        }

        let preview = String(data: responseData.prefix(200), encoding: .utf8) ?? ""
        throw APIError.unknown("No image data found in Gemini response. Preview: \(preview)")
    }

    private func extractImageFromPart(_ part: [String: Any]) -> Data? {
        let type = part["type"] as? String
        // { "type": "image_url", "image_url": { "url": "data:image/png;base64,..." } }
        if type == "image_url",
           let imageUrl = part["image_url"] as? [String: Any],
           let urlStr = imageUrl["url"] as? String {
            return decodeBase64Image(urlStr)
        }
        // { "type": "image", "data": "...", "media_type": "..." }
        if type == "image",
           let b64 = part["data"] as? String,
           let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
           data.count > 100 { return data }
        return nil
    }

    private func decodeBase64Image(_ text: String) -> Data? {
        // Direct base64
        if let data = Data(base64Encoded: text, options: .ignoreUnknownCharacters), data.count > 100 {
            return data
        }
        // Data URI: data:image/png;base64,<data>
        if let range = text.range(of: "base64,") {
            let b64 = String(text[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters), data.count > 100 {
                return data
            }
        }
        return nil
    }
}

// MARK: - APIError alias

private typealias APIError = Domain.APIError
