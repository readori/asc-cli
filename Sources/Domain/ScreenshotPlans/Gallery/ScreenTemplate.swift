import Foundation

/// Layout for a single screen type — where headline and devices go.
///
/// Supports single device, side-by-side (2 devices), or triple fan (3 devices).
public struct ScreenTemplate: Sendable, Equatable, Codable {
    public let headline: TextSlot
    public let devices: [DeviceSlot]
    public let decorations: [Decoration]

    public init(
        headline: TextSlot,
        devices: [DeviceSlot] = [],
        decorations: [Decoration] = []
    ) {
        self.headline = headline
        self.devices = devices
        self.decorations = decorations
    }

    /// Convenience: single device.
    public init(
        headline: TextSlot,
        device: DeviceSlot,
        decorations: [Decoration] = []
    ) {
        self.headline = headline
        self.devices = [device]
        self.decorations = decorations
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        headline = try c.decode(TextSlot.self, forKey: .headline)
        // Support both "device" (single) and "devices" (array) in JSON
        if let arr = try? c.decode([DeviceSlot].self, forKey: .devices) {
            devices = arr
        } else if let single = try? c.decode(DeviceSlot.self, forKey: .device) {
            devices = [single]
        } else {
            devices = []
        }
        decorations = try c.decodeIfPresent([Decoration].self, forKey: .decorations) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case headline, device, devices, decorations
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(headline, forKey: .headline)
        if !devices.isEmpty { try c.encode(devices, forKey: .devices) }
        if !decorations.isEmpty { try c.encode(decorations, forKey: .decorations) }
    }

    /// Number of device slots.
    public var deviceCount: Int { devices.count }
}

/// Where and how text appears in a screen.
public struct TextSlot: Sendable, Equatable, Codable {
    public let y: Double
    public let size: Double
    public let weight: Int
    public let align: String

    public init(y: Double, size: Double, weight: Int = 900, align: String = "center") {
        self.y = y
        self.size = size
        self.weight = weight
        self.align = align
    }
}

/// Where the device frame appears in a screen.
public struct DeviceSlot: Sendable, Equatable, Codable {
    public let x: Double
    public let y: Double
    public let width: Double

    public init(x: Double = 0.5, y: Double, width: Double) {
        self.x = x
        self.y = y
        self.width = width
    }
}

/// An ambient decorative shape (gem, orb, sparkle, arrow).
public struct Decoration: Sendable, Equatable, Codable {
    public let shape: DecorationShape
    public let x: Double
    public let y: Double
    public let size: Double
    public let opacity: Double

    public init(shape: DecorationShape, x: Double, y: Double, size: Double, opacity: Double = 1.0) {
        self.shape = shape
        self.x = x
        self.y = y
        self.size = size
        self.opacity = opacity
    }
}

public enum DecorationShape: String, Sendable, Equatable, Codable {
    case gem, orb, sparkle, arrow
}
