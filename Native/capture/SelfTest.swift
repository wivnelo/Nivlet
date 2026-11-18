#if NIVLET_SELFTEST
import AppKit
import CoreImage

/// Test-only hook (compiled with -D NIVLET_SELFTEST, never in release builds): selects a region,
/// adds one annotation of each kind, renders it to `path`, and exercises copy and the size limits.
extension Session {
    func runSelfTest(path: String) {
        guard let v = testView else { return }
        let b = v.bounds
        let sel = CGRect(x: b.width * 0.2, y: b.height * 0.25, width: b.width * 0.5, height: b.height * 0.45).integral
        testSelect(sel, index: v.index)
        let r = Annotation(tool: .rect, color: palette[0], width: 4, start: CGPoint(x: sel.minX + 30, y: sel.maxY - 30))
        r.points[1] = CGPoint(x: sel.minX + 330, y: sel.maxY - 160)
        let a = Annotation(tool: .arrow, color: palette[0], width: 4, start: CGPoint(x: sel.midX + 160, y: sel.minY + 60))
        a.points[1] = CGPoint(x: sel.minX + 340, y: sel.maxY - 170)
        let p = Annotation(tool: .pen, color: palette[4], width: 4, start: CGPoint(x: sel.minX + 40, y: sel.minY + 60))
        p.points = (0..<40).map { CGPoint(x: sel.minX + 40 + CGFloat($0) * 6, y: sel.minY + 60 + sin(CGFloat($0) / 4) * 20) }
        let t = Annotation(tool: .text, color: palette[0], width: 0, start: CGPoint(x: sel.minX + 30, y: sel.minY + 120))
        t.text = "Nivlet 截图自检 ①"; t.fontSize = 22
        let m = Annotation(tool: .mosaic, color: .black, width: 0, start: CGPoint(x: sel.midX, y: sel.midY))
        m.points[1] = CGPoint(x: sel.midX + 260, y: sel.midY + 90)
        let k = Annotation(tool: .mosaic, color: .black, width: 0, start: CGPoint(x: sel.midX, y: sel.midY - 120))
        k.points[1] = CGPoint(x: sel.midX + 260, y: sel.midY - 40); k.mosaicMode = .blackout
        testAnnotate([r, a, p, t, m, k])
        if ProcessInfo.processInfo.environment["NIVLET_SELFTEST_PANEL"] == "ocr" { testRecognize() }
        else { testShowTextEditing(in: v, at: CGPoint(x: sel.minX + 32, y: sel.minY + 126)) }
        testSaveRender(to: path)
    }
}

/// Decodes a generated QR code and reads text from a generated image, independent of the screen.
func selfTestRecognition(_ done: @escaping ([String: Any]) -> Void) {
    let filter = CIFilter(name: "CIQRCodeGenerator", parameters: ["inputMessage": Data("https://wivnelo.github.io/Nivlet/".utf8), "inputCorrectionLevel": "M"])!
    let qr = filter.outputImage!.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
    let qrImage = CIContext().createCGImage(qr, from: qr.extent)!
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1200, pixelsHigh: 300, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.white.setFill(); NSRect(x: 0, y: 0, width: 1200, height: 300).fill()
    ("截图识别自检 Screenshot OCR 2026" as NSString).draw(at: NSPoint(x: 40, y: 180), withAttributes: [.font: NSFont.systemFont(ofSize: 48), .foregroundColor: NSColor.black])
    ("設定を保存しました" as NSString).draw(at: NSPoint(x: 40, y: 80), withAttributes: [.font: NSFont.systemFont(ofSize: 48), .foregroundColor: NSColor.black])
    NSGraphicsContext.restoreGraphicsState()
    Recognition.codes(in: qrImage) { codes in
        Recognition.text(in: rep.cgImage!, interface: "zh-Hans") { lines in
            // Same image with an English interface: Chinese must still be read (regression test).
            Recognition.text(in: rep.cgImage!, interface: "en") { english in
                done(["qr": (try? codes.get().map(\.payload)) ?? [], "ocr": (try? lines.get()) ?? [], "ocrEnglishUI": (try? english.get()) ?? []])
            }
        }
    }
}

@MainActor
func selfTestSnapshotCard(path: String) -> Bool {
    guard let window = NSApp.windows.first(where: { $0 is TranslatePanelWindow && $0.isVisible }), let view = window.contentView else { return false }
    let scale = window.backingScaleFactor
    let size = view.bounds.size
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return false }
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    window.effectiveAppearance.performAsCurrentDrawingAppearance {
        view.layer?.render(in: NSGraphicsContext.current!.cgContext)
    }
    NSGraphicsContext.restoreGraphicsState()
    return (try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))) != nil
}
#endif
