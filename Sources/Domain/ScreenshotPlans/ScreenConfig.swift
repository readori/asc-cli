public struct ScreenConfig: Sendable, Equatable, Identifiable {
    public let id: String
    public let index: Int
    public let screenshotFile: String
    public let heading: String
    public let subheading: String
    public let layoutMode: LayoutMode
    public let visualDirection: String
    public let imagePrompt: String

    public init(
        index: Int,
        screenshotFile: String,
        heading: String,
        subheading: String,
        layoutMode: LayoutMode,
        visualDirection: String,
        imagePrompt: String
    ) {
        self.id = "\(index)"
        self.index = index
        self.screenshotFile = screenshotFile
        self.heading = heading
        self.subheading = subheading
        self.layoutMode = layoutMode
        self.visualDirection = visualDirection
        self.imagePrompt = imagePrompt
    }
}

// Custom Codable: `id` is derived from `index`, never round-tripped through JSON.
extension ScreenConfig: Codable {
    private enum CodingKeys: String, CodingKey {
        case index, screenshotFile, heading, subheading, layoutMode, visualDirection, imagePrompt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let index = try c.decode(Int.self, forKey: .index)
        self.init(
            index: index,
            screenshotFile: try c.decode(String.self, forKey: .screenshotFile),
            heading: try c.decode(String.self, forKey: .heading),
            subheading: try c.decode(String.self, forKey: .subheading),
            layoutMode: try c.decode(LayoutMode.self, forKey: .layoutMode),
            visualDirection: try c.decode(String.self, forKey: .visualDirection),
            imagePrompt: try c.decode(String.self, forKey: .imagePrompt)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(index, forKey: .index)
        try c.encode(screenshotFile, forKey: .screenshotFile)
        try c.encode(heading, forKey: .heading)
        try c.encode(subheading, forKey: .subheading)
        try c.encode(layoutMode, forKey: .layoutMode)
        try c.encode(visualDirection, forKey: .visualDirection)
        try c.encode(imagePrompt, forKey: .imagePrompt)
    }
}
