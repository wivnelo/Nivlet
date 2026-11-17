import AppKit

/// Annotation tools available in the overlay toolbar.
enum Tool: String, CaseIterable {
    case rect, arrow, pen, text, mosaic
}

enum MosaicMode: String { case pixelate, blackout }

/// One vector annotation. Geometry is in the overlay view's coordinates (points, bottom-left origin)
/// so the same drawing code serves the live view and the full-resolution export.
final class Annotation {
    let tool: Tool
    var color: NSColor
    var width: CGFloat
    var points: [CGPoint]
    var text: String = ""
    var fontSize: CGFloat = 16
    var mosaicMode: MosaicMode = .pixelate
    var mosaicBlock: CGFloat = 12
    var cachedMosaic: CGImage?

    init(tool: Tool, color: NSColor, width: CGFloat, start: CGPoint) {
        self.tool = tool; self.color = color; self.width = width; self.points = [start, start]
    }

    var rect: CGRect {
        guard let a = points.first, let b = points.last else { return .zero }
        return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    /// Area covered by a text annotation, used to click back into it for editing.
    var textBounds: CGRect {
        guard tool == .text, let origin = points.first else { return .zero }
        let size = (text as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: fontSize, weight: .semibold)])
        return CGRect(origin: origin, size: size)
    }

    var isMeaningful: Bool {
        switch tool {
        case .pen: return points.count > 2
        case .text: return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default: return rect.width >= 3 || rect.height >= 3
        }
    }

    /// Draws into the current NSGraphicsContext. `frozen` and `pixelScale` are needed for mosaic,
    /// which samples the original pixels so annotations underneath never leak through.
    func draw(frozen: CGImage, viewHeight: CGFloat, pixelScale: CGFloat) {
        color.setStroke(); color.setFill()
        switch tool {
        case .rect:
            let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
            path.lineWidth = width; path.lineJoinStyle = .round; path.stroke()
        case .pen:
            let path = NSBezierPath()
            path.lineWidth = width; path.lineCapStyle = .round; path.lineJoinStyle = .round
            path.move(to: points[0]); points.dropFirst().forEach { path.line(to: $0) }
            path.stroke()
        case .arrow:
            drawArrow()
        case .text:
            let shadow = NSShadow()
            shadow.shadowColor = color.brightnessComponentSafe > 0.6 ? NSColor.black.withAlphaComponent(0.7) : NSColor.white
            shadow.shadowBlurRadius = 3; shadow.shadowOffset = .zero
            let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: fontSize, weight: .semibold), .foregroundColor: color, .shadow: shadow]
            (text as NSString).draw(at: points[0], withAttributes: attributes)
        case .mosaic:
            drawMosaic(frozen: frozen, viewHeight: viewHeight, pixelScale: pixelScale)
        }
    }

    private func drawArrow() {
        guard let a = points.first, let b = points.last, a != b else { return }
        let angle = atan2(b.y - a.y, b.x - a.x)
        let head = max(12, width * 4.2)
        let spread: CGFloat = .pi / 7
        let base = CGPoint(x: b.x - cos(angle) * head * 0.8, y: b.y - sin(angle) * head * 0.8)
        let shaft = NSBezierPath(); shaft.lineWidth = width; shaft.lineCapStyle = .round
        shaft.move(to: a); shaft.line(to: base); shaft.stroke()
        let tip = NSBezierPath()
        tip.move(to: b)
        tip.line(to: CGPoint(x: b.x - cos(angle - spread) * head, y: b.y - sin(angle - spread) * head))
        tip.line(to: CGPoint(x: b.x - cos(angle + spread) * head, y: b.y - sin(angle + spread) * head))
        tip.close(); tip.lineJoinStyle = .round; tip.lineWidth = 1; tip.fill(); tip.stroke()
    }

    private func drawMosaic(frozen: CGImage, viewHeight: CGFloat, pixelScale: CGFloat) {
        let r = rect.integral
        guard r.width > 0, r.height > 0 else { return }
        if mosaicMode == .blackout {
            NSColor.black.setFill(); NSBezierPath(rect: r).fill(); return
        }
        if cachedMosaic == nil { cachedMosaic = Annotation.pixelate(frozen, rect: r, viewHeight: viewHeight, pixelScale: pixelScale, block: mosaicBlock) }
        guard let image = cachedMosaic, let cg = NSGraphicsContext.current?.cgContext else { return }
        cg.saveGState(); cg.interpolationQuality = .none; cg.draw(image, in: r); cg.restoreGState()
    }

    /// Averages blocks of the original image. Large blocks are the default because small ones can be
    /// partially reversed on text; blackout is offered for anything sensitive.
    static func pixelate(_ image: CGImage, rect: CGRect, viewHeight: CGFloat, pixelScale: CGFloat, block: CGFloat) -> CGImage? {
        let crop = CGRect(x: rect.minX * pixelScale, y: (viewHeight - rect.maxY) * pixelScale,
                          width: rect.width * pixelScale, height: rect.height * pixelScale).integral
        guard let piece = image.cropping(to: crop) else { return nil }
        let w = max(1, Int(rect.width / block)), h = max(1, Int(rect.height / block))
        guard let small = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        small.interpolationQuality = .medium
        small.draw(piece, in: CGRect(x: 0, y: 0, width: w, height: h))
        return small.makeImage()
    }
}

extension NSColor {
    var brightnessComponentSafe: CGFloat { usingColorSpace(.deviceRGB)?.brightnessComponent ?? 0 }
    var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "#000000" }
        return String(format: "#%02X%02X%02X", Int(round(c.redComponent * 255)), Int(round(c.greenComponent * 255)), Int(round(c.blueComponent * 255)))
    }
}

/// Palette shared by the toolbar and keyboard shortcuts 1–6.
let palette: [NSColor] = [
    NSColor(srgbRed: 1.00, green: 0.23, blue: 0.19, alpha: 1),
    NSColor(srgbRed: 1.00, green: 0.58, blue: 0.00, alpha: 1),
    NSColor(srgbRed: 1.00, green: 0.80, blue: 0.00, alpha: 1),
    NSColor(srgbRed: 0.20, green: 0.78, blue: 0.35, alpha: 1),
    NSColor(srgbRed: 0.00, green: 0.48, blue: 1.00, alpha: 1),
    NSColor(srgbRed: 0.11, green: 0.11, blue: 0.12, alpha: 1),
]
let strokeWidths: [CGFloat] = [2, 4, 7]
let textSizes: [CGFloat] = [13, 18, 26]
let mosaicBlocks: [CGFloat] = [8, 12, 20]
