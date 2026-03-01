import SwiftUI

struct ThemePalette {
    static func focusColor(for scheme: ColorScheme) -> Color {
        color(lightHex: "#FF5666", scheme: scheme)
    }

    static func breakColor(for scheme: ColorScheme) -> Color {
        color(lightHex: "#495F41", scheme: scheme)
    }

    static func growthUpColor(for scheme: ColorScheme) -> Color {
        color(lightHex: "#2E5339", scheme: scheme)
    }

    static func growthDownColor(for scheme: ColorScheme) -> Color {
        color(lightHex: "#30011E", scheme: scheme)
    }

    static func nowLineColor(for scheme: ColorScheme) -> Color {
        color(lightHex: "#1D4F2E", scheme: scheme)
    }

    static func color(lightHex: String, scheme: ColorScheme) -> Color {
        guard let rgb = RGB(hex: lightHex) else { return .primary }
        let shouldInvert = scheme == .dark && AppSettings.shared.invertThemeColorsInDarkMode
        let used = shouldInvert ? rgb.inverted : rgb
        return Color(red: used.red, green: used.green, blue: used.blue)
    }
}

private struct RGB {
    let red: Double
    let green: Double
    let blue: Double

    var inverted: RGB {
        RGB(red: 1 - red, green: 1 - green, blue: 1 - blue)
    }

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init?(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else { return nil }

        red = Double((value >> 16) & 0xFF) / 255.0
        green = Double((value >> 8) & 0xFF) / 255.0
        blue = Double(value & 0xFF) / 255.0
    }
}