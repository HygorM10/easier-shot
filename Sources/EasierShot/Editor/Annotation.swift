import AppKit

enum Tool: String, CaseIterable, Identifiable {
    case select, pencil, line, arrow, rectangle, filledRectangle, ellipse, marker, text, counter, pixelate

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .select: return "arrow.up.and.down.and.arrow.left.and.right"
        case .pencil: return "pencil"
        case .line: return "line.diagonal"
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .filledRectangle: return "rectangle.fill"
        case .ellipse: return "circle"
        case .marker: return "highlighter"
        case .text: return "textformat"
        case .counter: return "1.circle.fill"
        case .pixelate: return "checkerboard.rectangle"
        }
    }

    var titleKey: L {
        switch self {
        case .select: return .toolSelect
        case .pencil: return .toolPencil
        case .line: return .toolLine
        case .arrow: return .toolArrow
        case .rectangle: return .toolRectangle
        case .filledRectangle: return .toolFilledRectangle
        case .ellipse: return .toolEllipse
        case .marker: return .toolMarker
        case .text: return .toolText
        case .counter: return .toolCounter
        case .pixelate: return .toolPixelate
        }
    }

    /// Freehand tools keep every point of the stroke; the others only need start and end.
    var isFreehand: Bool { self == .pencil || self == .marker }
}

/// One drawing on top of the screenshot. Coordinates are in points, origin at the top-left of the screen.
struct Annotation: Identifiable {
    let id = UUID()
    var tool: Tool
    var color: NSColor
    var lineWidth: CGFloat
    var points: [CGPoint]
    var text: String = ""
    var number: Int = 0
    /// Cached pixelation result, filled in when a pixelate annotation is finished.
    var mosaic: CGImage?

    static func fontSize(for lineWidth: CGFloat) -> CGFloat { 12 + lineWidth * 3 }
    static func textFont(for lineWidth: CGFloat) -> NSFont {
        .systemFont(ofSize: fontSize(for: lineWidth), weight: .semibold)
    }
}

struct TextDraft: Identifiable {
    let id = UUID()
    var position: CGPoint
    var text: String = ""
}
