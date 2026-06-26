import SwiftUI
import UIKit

extension Color {
    func adjusted(saturation: Double = 1.0, brightness: Double = 1.0) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(
            hue: Double(h),
            saturation: Double(s) * saturation,
            brightness: Double(b) * brightness,
            opacity: Double(a)
        )
    }

    init(hex: String, opacity: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: opacity * Double(a) / 255.0
        )
    }

    init(uiColor: UIColor) {
        self.init(uiColor)
    }
}

extension UIColor {
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}

extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor.dynamicColor(
            light: UIColor(light),
            dark: UIColor(dark)
        ))
    }
}

extension Color {
    static let bloomBackground = Color.dynamic(
        light: Color(hex: "F2F2F7"),
        dark: Color(hex: "000000")
    )

    static let bloomSurface = Color.dynamic(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "1C1C1E")
    )

    static let bloomSurfaceSecondary = Color.dynamic(
        light: Color(hex: "F9F9FB"),
        dark: Color(hex: "2C2C2E")
    )

    static let bloomTextPrimary = Color.dynamic(
        light: Color(hex: "1C1C1E"),
        dark: Color(hex: "F5F5F7")
    )

    static let bloomTextSecondary = Color.dynamic(
        light: Color(hex: "8E8E93"),
        dark: Color(hex: "98989D")
    )

    static let bloomTextTertiary = Color.dynamic(
        light: Color(hex: "AEAEB2"),
        dark: Color(hex: "636366")
    )

    static let bloomPrimary = Color(hex: "34C759")

    static let bloomPrimaryMuted = Color(hex: "34C759", opacity: 0.12)

    static let bloomPrimarySubtle = Color(hex: "34C759", opacity: 0.06)

    static let bloomWater = Color(hex: "32ADE6")

    static let bloomWaterMuted = Color(hex: "32ADE6", opacity: 0.12)

    static let bloomGold = Color(hex: "FFD60A")

    static let bloomGoldMuted = Color(hex: "FFD60A", opacity: 0.15)

    static let bloomSuccess = Color(hex: "34C759")

    static let bloomWarning = Color(hex: "FF9F0A")

    static let bloomError = Color(hex: "FF3B30")

    static let bloomInfo = Color(hex: "007AFF")

    static let bloomBorder = Color.dynamic(
        light: Color(hex: "000000", opacity: 0.06),
        dark: Color(hex: "FFFFFF", opacity: 0.08)
    )

    static let bloomDivider = Color.dynamic(
        light: Color(hex: "3C3C43", opacity: 0.08),
        dark: Color(hex: "FFFFFF", opacity: 0.06)
    )

    static let bloomFill = Color.dynamic(
        light: Color(hex: "787880", opacity: 0.12),
        dark: Color(hex: "787880", opacity: 0.2)
    )

    static let bloomCardBorder = Color.dynamic(
        light: Color(hex: "000000", opacity: 0.04),
        dark: Color(hex: "FFFFFF", opacity: 0.06)
    )

    static let bloomSecondary = Color(hex: "8BC34A")

    static let bloomDeep = Color(hex: "2E7D32")

    static let bloomLeaf = Color(hex: "3D8A2E")

    static let bloomSoil = Color(hex: "8D6E4F")

    static let bloomDanger = Color(hex: "FF3B30")
}

extension Color {
    static func healthColor(_ health: Double) -> Color {
        switch health {
        case ..<25:  return .bloomError
        case ..<50:  return .bloomWarning
        case ..<80:  return .bloomPrimary
        default:     return .bloomSuccess
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}
