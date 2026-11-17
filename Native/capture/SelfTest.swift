#if NIVLET_SELFTEST
import AppKit

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
        testSaveRender(to: path)
    }
}
#endif
