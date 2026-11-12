import SwiftUI
import AppKit

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

/// The EasierShot palette.
enum Palette {
    static let creamNS = NSColor(hex: 0xFFFBEB)
    static let paleYellowNS = NSColor(hex: 0xFFE9A6)
    static let indigoNS = NSColor(hex: 0x3F51B5)
    static let amberNS = NSColor(hex: 0xFFC107)
    static let navyNS = NSColor(hex: 0x1E2445)

    static let cream = Color(nsColor: creamNS)
    static let paleYellow = Color(nsColor: paleYellowNS)
    static let indigo = Color(nsColor: indigoNS)
    static let amber = Color(nsColor: amberNS)
    static let navy = Color(nsColor: navyNS)
}

struct Theme {
    let background: Color
    let surface: Color
    let text: Color
    let secondaryText: Color
    let primary: Color
    let onPrimary: Color
    let accent: Color

    static func current(_ scheme: ColorScheme) -> Theme {
        scheme == .dark ? dark : light
    }

    static let light = Theme(
        background: Palette.cream,
        surface: Palette.paleYellow,
        text: Palette.navy,
        secondaryText: Palette.navy.opacity(0.65),
        primary: Palette.indigo,
        onPrimary: Palette.cream,
        accent: Palette.amber
    )

    static let dark = Theme(
        background: Palette.navy,
        surface: Palette.indigo.opacity(0.45),
        text: Palette.cream,
        secondaryText: Palette.paleYellow.opacity(0.75),
        primary: Palette.amber,
        onPrimary: Palette.navy,
        accent: Palette.indigo
    )
}
