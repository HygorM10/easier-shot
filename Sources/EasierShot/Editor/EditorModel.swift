import AppKit
import SwiftUI

enum SelectionHandle: CaseIterable {
    case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left

    var movesLeft: Bool { self == .topLeft || self == .left || self == .bottomLeft }
    var movesRight: Bool { self == .topRight || self == .right || self == .bottomRight }
    var movesTop: Bool { self == .topLeft || self == .top || self == .topRight }
    var movesBottom: Bool { self == .bottomLeft || self == .bottom || self == .bottomRight }

    func point(in rect: CGRect) -> CGPoint {
        let x = movesLeft ? rect.minX : (movesRight ? rect.maxX : rect.midX)
        let y = movesTop ? rect.minY : (movesBottom ? rect.maxY : rect.midY)
        return CGPoint(x: x, y: y)
    }
}

/// State of the editor for one screen. All geometry is in points, origin top-left.
@MainActor
final class EditorModel: ObservableObject {
    static let swatches: [NSColor] = [
        NSColor(hex: 0xE53935), NSColor(hex: 0xFB8C00), Palette.amberNS, NSColor(hex: 0x43A047),
        NSColor(hex: 0x00ACC1), Palette.indigoNS, NSColor(hex: 0xD81B60), Palette.navyNS, .white,
    ]
    static let lineWidthRange: ClosedRange<CGFloat> = 1...20

    let image: CGImage
    let screen: NSScreen
    let bounds: CGRect
    let scale: CGFloat
    weak var coordinator: CaptureCoordinator?

    @Published var selection: CGRect?
    @Published var tool: Tool = .select {
        didSet { if tool != .text { commitText() } }
    }
    @Published var color: NSColor = EditorModel.swatches[0]
    @Published var lineWidth: CGFloat = 3
    @Published private(set) var annotations: [Annotation] = []
    @Published private(set) var redoStack: [Annotation] = []
    @Published private(set) var current: Annotation?
    @Published var textDraft: TextDraft?
    @Published var showOptions = false
    @Published private(set) var isDragging = false

    private enum DragMode {
        case idle
        case newSelection(anchor: CGPoint)
        case move(grab: CGPoint, original: CGRect)
        case resize(SelectionHandle, original: CGRect)
        case draw
    }

    private var drag: DragMode = .idle
    private var dragStarted = false

    init(image: CGImage, screen: NSScreen) {
        self.image = image
        self.screen = screen
        self.bounds = CGRect(origin: .zero, size: screen.frame.size)
        self.scale = CGFloat(image.width) / max(screen.frame.width, 1)
    }

    var visibleAnnotations: [Annotation] {
        current.map { annotations + [$0] } ?? annotations
    }

    // MARK: - Mouse handling

    func dragChanged(start: CGPoint, location: CGPoint) {
        if !dragStarted {
            dragStarted = true
            begin(at: start)
        }
        update(to: location)
    }

    func dragEnded(location: CGPoint) {
        if !dragStarted { begin(at: location) }
        update(to: location)
        finish()
        dragStarted = false
    }

    private func begin(at rawPoint: CGPoint) {
        let p = clamp(rawPoint)
        commitText()

        guard let selection else {
            drag = .newSelection(anchor: p)
            isDragging = true
            return
        }

        if let handle = handle(at: p, in: selection) {
            drag = .resize(handle, original: selection)
            isDragging = true
            return
        }

        switch tool {
        case .select:
            drag = selection.contains(p) ? .move(grab: p, original: selection) : .newSelection(anchor: p)
            isDragging = true
        case .text:
            textDraft = TextDraft(position: p)
            drag = .idle
        case .counter:
            let number = annotations.filter { $0.tool == .counter }.count + 1
            add(Annotation(tool: .counter, color: color, lineWidth: lineWidth, points: [p], number: number))
            drag = .idle
        default:
            current = Annotation(tool: tool, color: color, lineWidth: lineWidth, points: [p])
            drag = .draw
            isDragging = true
        }
    }

    private func update(to rawPoint: CGPoint) {
        let p = clamp(rawPoint)
        switch drag {
        case .idle:
            break

        case .newSelection(let anchor):
            selection = CGRect(x: min(anchor.x, p.x), y: min(anchor.y, p.y),
                               width: abs(p.x - anchor.x), height: abs(p.y - anchor.y))

        case .move(let grab, let original):
            var rect = original.offsetBy(dx: p.x - grab.x, dy: p.y - grab.y)
            rect.origin.x = min(max(rect.minX, bounds.minX), bounds.maxX - rect.width)
            rect.origin.y = min(max(rect.minY, bounds.minY), bounds.maxY - rect.height)
            selection = rect

        case .resize(let handle, let original):
            var minX = original.minX, maxX = original.maxX
            var minY = original.minY, maxY = original.maxY
            if handle.movesLeft { minX = p.x }
            if handle.movesRight { maxX = p.x }
            if handle.movesTop { minY = p.y }
            if handle.movesBottom { maxY = p.y }
            selection = CGRect(x: min(minX, maxX), y: min(minY, maxY),
                               width: abs(maxX - minX), height: abs(maxY - minY))

        case .draw:
            guard var annotation = current else { return }
            if annotation.tool.isFreehand {
                annotation.points.append(p)
            } else {
                annotation.points = [annotation.points[0], p]
            }
            current = annotation
        }
    }

    private func finish() {
        switch drag {
        case .newSelection, .resize:
            if let rect = selection, rect.width < 3 || rect.height < 3 {
                selection = nil
            }
        case .draw:
            if var annotation = current, isMeaningful(annotation) {
                if annotation.tool == .pixelate {
                    // Compute once; while dragging it is recomputed live because the rectangle changes.
                    annotation.mosaic = AnnotationRenderer.mosaic(for: annotation, source: image, scale: scale)
                }
                add(annotation)
            }
            current = nil
        case .idle, .move:
            break
        }
        drag = .idle
        isDragging = false
    }

    private func isMeaningful(_ annotation: Annotation) -> Bool {
        guard let first = annotation.points.first, let last = annotation.points.last else { return false }
        if annotation.tool.isFreehand { return true }
        return hypot(last.x - first.x, last.y - first.y) >= 2
    }

    private func clamp(_ p: CGPoint) -> CGPoint {
        CGPoint(x: min(max(p.x, bounds.minX), bounds.maxX),
                y: min(max(p.y, bounds.minY), bounds.maxY))
    }

    private func handle(at p: CGPoint, in rect: CGRect) -> SelectionHandle? {
        SelectionHandle.allCases.first { handle in
            let hp = handle.point(in: rect)
            return hypot(hp.x - p.x, hp.y - p.y) <= 9
        }
    }

    // MARK: - Editing

    private func add(_ annotation: Annotation) {
        annotations.append(annotation)
        redoStack.removeAll()
    }

    var canUndo: Bool { !annotations.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func undo() {
        guard let last = annotations.popLast() else { return }
        redoStack.append(last)
    }

    func redo() {
        guard let last = redoStack.popLast() else { return }
        annotations.append(last)
    }

    func changeLineWidth(by delta: CGFloat) {
        let range = EditorModel.lineWidthRange
        lineWidth = min(max(lineWidth + delta, range.lowerBound), range.upperBound)
    }

    func commitText() {
        guard let draft = textDraft else { return }
        textDraft = nil
        guard !draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        add(Annotation(tool: .text, color: color, lineWidth: lineWidth,
                       points: [draft.position], text: draft.text))
    }

    func perform(_ action: EditorAction) {
        coordinator?.handle(action, from: self)
    }

    // MARK: - Layout helpers

    /// Center point for the toolbar: below the selection, else above it, else inside it.
    func toolbarCenter(for selection: CGRect, toolbarSize: CGSize) -> CGPoint {
        let margin: CGFloat = 10
        let halfW = toolbarSize.width / 2, halfH = toolbarSize.height / 2
        let x = min(max(selection.midX, bounds.minX + halfW + margin), bounds.maxX - halfW - margin)

        var y = selection.maxY + margin + halfH
        if y + halfH > bounds.maxY - margin {
            y = selection.minY - margin - halfH
            if y - halfH < bounds.minY + margin {
                y = selection.maxY - margin - halfH
            }
        }
        return CGPoint(x: x, y: y)
    }

    /// Center point for the vertical actions bar: right of the selection, else left, else inside it.
    /// It grows away from the tools bar and never overlaps it.
    func actionBarCenter(for selection: CGRect, barSize: CGSize, avoiding toolsFrame: CGRect) -> CGPoint {
        let margin: CGFloat = 10
        let halfW = barSize.width / 2, halfH = barSize.height / 2

        var x = selection.maxX + margin + halfW
        if x + halfW > bounds.maxX - margin {
            x = selection.minX - margin - halfW
            if x - halfW < bounds.minX + margin {
                x = selection.maxX - margin - halfW
            }
        }

        // Tools below the selection: align the bar's bottom with the selection and grow upwards.
        // Tools above it: align the top and grow downwards.
        let toolsBelow = toolsFrame.midY > selection.midY
        var y = toolsBelow ? selection.maxY - halfH : selection.minY + halfH
        y = min(max(y, bounds.minY + halfH + margin), bounds.maxY - halfH - margin)

        // Still colliding (e.g. tiny selection at a screen edge): step aside horizontally.
        let frame = CGRect(x: x - halfW, y: y - halfH, width: barSize.width, height: barSize.height)
        if frame.insetBy(dx: -6, dy: -6).intersects(toolsFrame) {
            let right = toolsFrame.maxX + margin + halfW
            let left = toolsFrame.minX - margin - halfW
            if right + halfW <= bounds.maxX - margin {
                x = right
            } else if left - halfW >= bounds.minX + margin {
                x = left
            }
        }
        return CGPoint(x: x, y: y)
    }

    // MARK: - Export

    /// Renders the selected area (or the full screen) with all annotations at native resolution.
    func renderOutput() -> (image: CGImage, rect: CGRect)? {
        commitText()

        let rect = (selection ?? bounds).integral.intersection(bounds)
        guard rect.width >= 1, rect.height >= 1 else { return nil }
        let pixelWidth = Int((rect.width * scale).rounded())
        let pixelHeight = Int((rect.height * scale).rounded())

        func makeContext(_ space: CGColorSpace) -> CGContext? {
            CGContext(data: nil, width: pixelWidth, height: pixelHeight, bitsPerComponent: 8,
                      bytesPerRow: 0, space: space,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        }
        let sRGB = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let ctx = image.colorSpace.flatMap(makeContext) ?? makeContext(sRGB) else { return nil }

        // Switch to top-left origin in points, then move the selection's corner to the origin.
        ctx.translateBy(x: 0, y: CGFloat(pixelHeight))
        ctx.scaleBy(x: scale, y: -scale)
        ctx.translateBy(x: -rect.minX, y: -rect.minY)

        AnnotationRenderer.drawImage(image, in: bounds, ctx)
        for annotation in annotations {
            AnnotationRenderer.draw(annotation, in: ctx, source: image, scale: scale)
        }

        guard let result = ctx.makeImage() else { return nil }
        return (result, rect)
    }
}
