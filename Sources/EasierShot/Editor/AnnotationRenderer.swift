import AppKit

/// Draws annotations into a CGContext whose origin is top-left with y growing downwards.
/// The same code is used for the live editor and for the exported image.
enum AnnotationRenderer {
    static func draw(_ a: Annotation, in ctx: CGContext, source: CGImage, scale: CGFloat) {
        guard let start = a.points.first, let end = a.points.last else { return }

        ctx.saveGState()
        defer { ctx.restoreGState() }

        let color = a.color.cgColor
        ctx.setStrokeColor(color)
        ctx.setFillColor(color)
        ctx.setLineWidth(a.lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        let rect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                          width: abs(end.x - start.x), height: abs(end.y - start.y))

        switch a.tool {
        case .select:
            break

        case .pencil:
            strokePath(a.points, lineWidth: a.lineWidth, in: ctx)

        case .marker:
            let width = a.lineWidth * 3 + 8
            ctx.setStrokeColor(color.copy(alpha: 0.4) ?? color)
            ctx.setFillColor(color.copy(alpha: 0.4) ?? color)
            ctx.setLineWidth(width)
            ctx.setLineCap(.butt)
            strokePath(a.points, lineWidth: width, in: ctx)

        case .line:
            ctx.move(to: start)
            ctx.addLine(to: end)
            ctx.strokePath()

        case .arrow:
            drawArrow(from: start, to: end, lineWidth: a.lineWidth, in: ctx)

        case .rectangle:
            ctx.setLineJoin(.miter)
            ctx.stroke(rect)

        case .filledRectangle:
            ctx.fill(rect)

        case .ellipse:
            ctx.strokeEllipse(in: rect)

        case .text:
            drawText(a.text, at: start, font: Annotation.textFont(for: a.lineWidth),
                     color: a.color, centered: false, in: ctx)

        case .counter:
            let radius = 10 + a.lineWidth * 1.5
            ctx.fillEllipse(in: CGRect(x: start.x - radius, y: start.y - radius,
                                       width: radius * 2, height: radius * 2))
            drawText("\(a.number)", at: start,
                     font: .systemFont(ofSize: radius * 1.1, weight: .bold),
                     color: contrastingColor(for: a.color), centered: true, in: ctx)

        case .pixelate:
            guard rect.width > 1, rect.height > 1 else { return }
            if let tiles = a.mosaic ?? mosaic(for: a, source: source, scale: scale) {
                // Nearest-neighbour upscaling turns each averaged sample into one flat block.
                ctx.interpolationQuality = .none
                drawImage(tiles, in: rect, ctx)
            } else {
                ctx.setFillColor(NSColor.gray.cgColor)
                ctx.fill(rect)
            }
        }
    }

    /// Side of one pixelation block, in points. Grows with the selected thickness.
    static func pixelBlockSize(for lineWidth: CGFloat) -> CGFloat { 8 + lineWidth * 2 }

    /// Tiny image with one pixel per block, each being the average color of the area it covers.
    /// The grid starts at the rectangle's own corner, so blocks never get cut at its edges.
    static func mosaic(for a: Annotation, source: CGImage, scale: CGFloat) -> CGImage? {
        guard let start = a.points.first, let end = a.points.last else { return nil }
        let rect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                          width: abs(end.x - start.x), height: abs(end.y - start.y))
        guard rect.width > 1, rect.height > 1 else { return nil }
        let block = pixelBlockSize(for: a.lineWidth)

        let full = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        let pixelRect = CGRect(x: rect.minX * scale, y: rect.minY * scale,
                               width: rect.width * scale, height: rect.height * scale)
            .integral.intersection(full)
        guard pixelRect.width >= 1, pixelRect.height >= 1,
              let crop = source.cropping(to: pixelRect) else { return nil }

        let columns = max(1, Int((rect.width / block).rounded(.up)))
        let rows = max(1, Int((rect.height / block).rounded(.up)))
        let space = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let small = CGContext(data: nil, width: columns, height: rows, bitsPerComponent: 8,
                                    bytesPerRow: 0, space: space,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        small.interpolationQuality = .high
        small.draw(crop, in: CGRect(x: 0, y: 0, width: columns, height: rows))
        return small.makeImage()
    }

    /// Draws a CGImage upright in a y-down context.
    static func drawImage(_ image: CGImage, in rect: CGRect, _ ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: rect.minX, y: rect.maxY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(image, in: CGRect(origin: .zero, size: rect.size))
        ctx.restoreGState()
    }

    private static func strokePath(_ points: [CGPoint], lineWidth: CGFloat, in ctx: CGContext) {
        guard let first = points.first else { return }
        if points.count == 1 {
            ctx.fillEllipse(in: CGRect(x: first.x - lineWidth / 2, y: first.y - lineWidth / 2,
                                       width: lineWidth, height: lineWidth))
            return
        }
        ctx.addLines(between: points)
        ctx.strokePath()
    }

    private static func drawArrow(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat, in ctx: CGContext) {
        let dx = end.x - start.x, dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0.5 else { return }
        let ux = dx / length, uy = dy / length
        let head = min(max(12, lineWidth * 4.5), length)
        let half = head * 0.5
        let base = CGPoint(x: end.x - ux * head, y: end.y - uy * head)

        ctx.setLineCap(.butt)
        ctx.move(to: start)
        ctx.addLine(to: base)
        ctx.strokePath()

        ctx.move(to: end)
        ctx.addLine(to: CGPoint(x: base.x - uy * half, y: base.y + ux * half))
        ctx.addLine(to: CGPoint(x: base.x + uy * half, y: base.y - ux * half))
        ctx.closePath()
        ctx.fillPath()
    }

    private static func drawText(_ string: String, at point: CGPoint, font: NSFont, color: NSColor,
                                 centered: Bool, in ctx: CGContext) {
        guard !string.isEmpty else { return }
        let attributed = NSAttributedString(string: string,
                                            attributes: [.font: font, .foregroundColor: color])
        var origin = point
        if centered {
            let size = attributed.size()
            origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
        }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        attributed.draw(at: origin)
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func contrastingColor(for color: NSColor) -> NSColor {
        guard let rgb = color.usingColorSpace(.sRGB) else { return .white }
        let luminance = 0.299 * rgb.redComponent + 0.587 * rgb.greenComponent + 0.114 * rgb.blueComponent
        return luminance > 0.6 ? Palette.navyNS : .white
    }
}
