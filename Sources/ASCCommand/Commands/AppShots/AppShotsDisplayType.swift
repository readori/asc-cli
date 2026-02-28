import ArgumentParser

/// Named App Store device types with their required screenshot dimensions.
/// Use with `--device-type` on `generate` and `translate` instead of specifying
/// raw `--output-width` / `--output-height` values.
enum AppShotsDisplayType: String, CaseIterable, ExpressibleByArgument {
    // iPhone
    case iphone69 = "APP_IPHONE_69"
    case iphone67 = "APP_IPHONE_67"
    case iphone65 = "APP_IPHONE_65"
    case iphone61 = "APP_IPHONE_61"
    case iphone58 = "APP_IPHONE_58"
    case iphone55 = "APP_IPHONE_55"
    case iphone47 = "APP_IPHONE_47"
    case iphone40 = "APP_IPHONE_40"
    case iphone35 = "APP_IPHONE_35"
    // iPad
    case ipadPro129 = "APP_IPAD_PRO_129"
    case ipadPro3Gen11 = "APP_IPAD_PRO_3GEN_11"
    case ipad105 = "APP_IPAD_105"
    case ipad97 = "APP_IPAD_97"
    // Other platforms
    case appleTv = "APP_APPLE_TV"
    case desktop = "APP_DESKTOP"
    case appleVisionPro = "APP_APPLE_VISION_PRO"

    /// Output pixel dimensions `(width, height)` for this device type.
    var dimensions: (width: Int, height: Int) {
        switch self {
        case .iphone69:       return (1320, 2868)
        case .iphone67:       return (1290, 2796)
        case .iphone65:       return (1242, 2688)
        case .iphone61:       return (1179, 2556)
        case .iphone58:       return (1125, 2436)
        case .iphone55:       return (1242, 2208)
        case .iphone47:       return (750, 1334)
        case .iphone40:       return (640, 1136)
        case .iphone35:       return (640, 960)
        case .ipadPro129:     return (2048, 2732)
        case .ipadPro3Gen11:  return (1668, 2388)
        case .ipad105:        return (1668, 2224)
        case .ipad97:         return (1536, 2048)
        case .appleTv:        return (1920, 1080)
        case .desktop:        return (2560, 1600)
        case .appleVisionPro: return (3840, 2160)
        }
    }
}
