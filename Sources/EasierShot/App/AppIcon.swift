import AppKit
import SwiftUI

/// The EasierShot mark: a capture frame with a flame inside.
enum AppIcon {
    /// Monochrome template image for the menu bar.
    static let menuBar: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            drawSymbol("viewfinder", pointSize: 15, weight: .medium, in: rect)
            drawSymbol("flame.fill", pointSize: 8, weight: .regular, in: rect)
            return true
        }
        image.isTemplate = true
        return image
    }()

    private static func drawSymbol(_ name: String, pointSize: CGFloat, weight: NSFont.Weight, in rect: NSRect) {
        let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration) else { return }
        let size = symbol.size
        symbol.draw(in: NSRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2,
                               width: size.width, height: size.height))
    }
}

/// Colored version of the mark for use inside the app's own windows.
struct AppMarkView: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(LinearGradient(colors: [Palette.indigo, Palette.navy],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "viewfinder")
                .font(.system(size: size * 0.62, weight: .medium))
                .foregroundStyle(Palette.cream)
            Image(systemName: "flame.fill")
                .font(.system(size: size * 0.32))
                .foregroundStyle(
                    LinearGradient(colors: [Palette.amber, Color(nsColor: NSColor(hex: 0xFF5A3C))],
                                   startPoint: .top, endPoint: .bottom)
                )
        }
        .frame(width: size, height: size)
    }
}
