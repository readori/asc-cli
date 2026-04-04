import Foundation

/// A deterministic composition plan for HTML-based App Store screenshot generation.
///
/// Unlike `ScreenshotDesign` (designed for AI generation), `CompositionPlan` gives full control
/// over device placement, text overlays, and backgrounds. The same plan always produces
/// identical output.
///
/// ## Format
/// ```json
/// {
///   "appName": "MyApp",
///   "canvas": { "width": 1320, "height": 2868 },
///   "defaults": {
///     "background": { "type": "solid", "color": "#0A1628" },
///     "textColor": "#FFFFFF",
///     "subtextColor": "#A8B8D0",
///     "accentColor": "#4A7CFF",
///     "font": "Inter"
///   },
///   "screens": [
///     {
///       "texts": [
///         { "content": "Hero Title", "x": 0.065, "y": 0.04, "fontSize": 0.1, "color": "#FFF" }
///       ],
///       "devices": [
///         { "screenshotFile": "hero.png", "mockup": "iPhone 17 Pro Max", "x": 0.5, "y": 0.6, "scale": 0.85 }
///       ]
///     }
///   ]
/// }
/// ```
///
/// All positions (`x`, `y`) and `fontSize` are **normalized 0–1** relative to canvas dimensions.
/// This means the same plan works at any resolution.
public struct CompositionPlan: Sendable, Equatable, Codable {
    public let appName: String
    public let canvas: CanvasSize
    public let defaults: SlideDefaults
    public let screens: [SlideComposition]

    public init(
        appName: String,
        canvas: CanvasSize,
        defaults: SlideDefaults,
        screens: [SlideComposition]
    ) {
        self.appName = appName
        self.canvas = canvas
        self.defaults = defaults
        self.screens = screens
    }
}

/// Canvas dimensions and optional display type identifier.
public struct CanvasSize: Sendable, Equatable, Codable {
    public let width: Int
    public let height: Int
    /// Optional App Store display type (e.g. `"APP_IPHONE_67"`).
    public let displayType: String?

    public init(width: Int, height: Int, displayType: String? = nil) {
        self.width = width
        self.height = height
        self.displayType = displayType
    }
}

/// Default styling applied to all slides unless overridden.
public struct SlideDefaults: Sendable, Equatable, Codable {
    public let background: SlideBackground
    public let textColor: String
    public let subtextColor: String
    public let accentColor: String
    public let font: String

    public init(
        background: SlideBackground,
        textColor: String,
        subtextColor: String,
        accentColor: String,
        font: String
    ) {
        self.background = background
        self.textColor = textColor
        self.subtextColor = subtextColor
        self.accentColor = accentColor
        self.font = font
    }
}

/// Background style for a slide.
public enum SlideBackground: Sendable, Equatable {
    case solid(String)
    case gradient(from: String, to: String, angle: Int)
}

extension SlideBackground: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, color, from, to, angle
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "gradient":
            let from = try c.decode(String.self, forKey: .from)
            let to = try c.decode(String.self, forKey: .to)
            let angle = try c.decodeIfPresent(Int.self, forKey: .angle) ?? 180
            self = .gradient(from: from, to: to, angle: angle)
        default:
            let color = try c.decode(String.self, forKey: .color)
            self = .solid(color)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .solid(let color):
            try c.encode("solid", forKey: .type)
            try c.encode(color, forKey: .color)
        case .gradient(let from, let to, let angle):
            try c.encode("gradient", forKey: .type)
            try c.encode(from, forKey: .from)
            try c.encode(to, forKey: .to)
            try c.encode(angle, forKey: .angle)
        }
    }
}

/// A single slide composition with text overlays and device placements.
public struct SlideComposition: Sendable, Equatable, Codable {
    /// Override background for this slide. `nil` uses `defaults.background`.
    public let background: SlideBackground?
    public let texts: [TextOverlay]
    public let devices: [DeviceSlot]

    public init(
        background: SlideBackground? = nil,
        texts: [TextOverlay],
        devices: [DeviceSlot]
    ) {
        self.background = background
        self.texts = texts
        self.devices = devices
    }
}

/// A text element positioned on a slide.
///
/// All coordinates are **normalized 0–1** relative to canvas size.
/// `fontSize` is relative to canvas **width** (e.g. `0.1` = 10% of width).
public struct TextOverlay: Sendable, Equatable {
    public let content: String
    /// Horizontal position (0 = left edge, 1 = right edge).
    public let x: Double
    /// Vertical position (0 = top edge, 1 = bottom edge).
    public let y: Double
    /// Font size relative to canvas width (0.1 = 10% of canvas width).
    public let fontSize: Double
    /// CSS font weight (100–900). Default: 700.
    public let fontWeight: Int
    /// Hex color string.
    public let color: String
    /// Font family override. `nil` uses `defaults.font`.
    public let font: String?
    /// Text alignment. Default: `left`.
    public let textAlign: TextAlignment

    public init(
        content: String,
        x: Double, y: Double,
        fontSize: Double,
        fontWeight: Int = 700,
        color: String,
        font: String? = nil,
        textAlign: TextAlignment = .left
    ) {
        self.content = content
        self.x = x
        self.y = y
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
        self.font = font
        self.textAlign = textAlign
    }

    public enum TextAlignment: String, Sendable, Equatable, Codable {
        case left
        case center
        case right
    }
}

extension TextOverlay: Codable {
    private enum CodingKeys: String, CodingKey {
        case content, x, y, fontSize, fontWeight, color, font, textAlign
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        content = try c.decode(String.self, forKey: .content)
        x = try c.decode(Double.self, forKey: .x)
        y = try c.decode(Double.self, forKey: .y)
        fontSize = try c.decode(Double.self, forKey: .fontSize)
        fontWeight = try c.decodeIfPresent(Int.self, forKey: .fontWeight) ?? 700
        color = try c.decode(String.self, forKey: .color)
        font = try c.decodeIfPresent(String.self, forKey: .font)
        textAlign = try c.decodeIfPresent(TextAlignment.self, forKey: .textAlign) ?? .left
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(content, forKey: .content)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
        try c.encode(fontSize, forKey: .fontSize)
        try c.encode(fontWeight, forKey: .fontWeight)
        try c.encode(color, forKey: .color)
        try c.encodeIfPresent(font, forKey: .font)
        if textAlign != .left { try c.encode(textAlign, forKey: .textAlign) }
    }
}

/// A device mockup placed on a slide, displaying a screenshot.
///
/// Positions are **normalized 0–1** (center point of the device).
/// `scale` is relative to canvas width (1.0 = device width equals canvas width).
public struct DeviceSlot: Sendable, Equatable {
    /// Screenshot filename to display inside the device.
    public let screenshotFile: String
    /// Device mockup name (looked up in mockups.json / devices.json).
    public let mockup: String
    /// Center X position (0 = left, 1 = right).
    public let x: Double
    /// Center Y position (0 = top, 1 = bottom).
    public let y: Double
    /// Scale relative to canvas width (1.0 = full canvas width).
    public let scale: Double
    /// Rotation in degrees. Default: 0.
    public let rotation: Double
    /// How the screenshot fills the device screen.
    public let contentMode: ContentMode

    public init(
        screenshotFile: String,
        mockup: String,
        x: Double, y: Double,
        scale: Double,
        rotation: Double = 0,
        contentMode: ContentMode = .fit
    ) {
        self.screenshotFile = screenshotFile
        self.mockup = mockup
        self.x = x
        self.y = y
        self.scale = scale
        self.rotation = rotation
        self.contentMode = contentMode
    }

    public enum ContentMode: String, Sendable, Equatable, Codable {
        case fit
        case fill
    }
}

extension DeviceSlot: Codable {
    private enum CodingKeys: String, CodingKey {
        case screenshotFile, mockup, x, y, scale, rotation, contentMode
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        screenshotFile = try c.decode(String.self, forKey: .screenshotFile)
        mockup = try c.decode(String.self, forKey: .mockup)
        x = try c.decode(Double.self, forKey: .x)
        y = try c.decode(Double.self, forKey: .y)
        scale = try c.decode(Double.self, forKey: .scale)
        rotation = try c.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
        contentMode = try c.decodeIfPresent(ContentMode.self, forKey: .contentMode) ?? .fit
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(screenshotFile, forKey: .screenshotFile)
        try c.encode(mockup, forKey: .mockup)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
        try c.encode(scale, forKey: .scale)
        if rotation != 0 { try c.encode(rotation, forKey: .rotation) }
        if contentMode != .fit { try c.encode(contentMode, forKey: .contentMode) }
    }
}
