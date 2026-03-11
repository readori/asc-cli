/// Pre-loaded assets needed to render HTML — no file I/O inside renderers.
struct RenderAssets: Sendable {
    let screenshotDataURIs: [String: String]   // filename → data:image/png;base64,...
    let mockups: [String: MockupInfo]          // device name → frame info

    static let empty = RenderAssets(screenshotDataURIs: [:], mockups: [:])
}

/// Mockup frame data for HTML embedding.
struct MockupInfo: Sendable {
    let dataURI: String
    let frameWidth: Int
    let frameHeight: Int
    let insetX: Int
    let insetY: Int
}
