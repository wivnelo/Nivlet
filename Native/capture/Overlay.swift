import AppKit

/// Borderless window covering one display, above full-screen apps and menus.
final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = true; hasShadow = false; backgroundColor = .black
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
        animationBehavior = .none
        setFrame(screen.frame, display: false)
    }
}

/// Draws one frozen display and forwards input to the session.
final class OverlayView: NSView {
    weak var session: Session?
    let frozen: FrozenScreen
    var index: Int

    init(frozen: FrozenScreen, index: Int) {
        self.frozen = frozen; self.index = index
        super.init(frame: NSRect(origin: .zero, size: frozen.screen.frame.size))
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self))
    }
    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var isOpaque: Bool { true }

    override func draw(_ dirtyRect: NSRect) { session?.draw(in: self) }
    override func mouseDown(with event: NSEvent) { session?.mouseDown(self, event) }
    override func mouseDragged(with event: NSEvent) { session?.mouseDragged(self, event) }
    override func mouseUp(with event: NSEvent) { session?.mouseUp(self, event) }
    override func mouseMoved(with event: NSEvent) { session?.mouseMoved(self, event) }
    override func mouseEntered(with event: NSEvent) { session?.mouseMoved(self, event) }
    override func rightMouseDown(with event: NSEvent) { session?.rightMouseDown(self) }
    override func keyDown(with event: NSEvent) { if session?.keyDown(event) != true { super.keyDown(with: event) } }
    override func cancelOperation(_ sender: Any?) { session?.escape() }

    func local(_ event: NSEvent) -> CGPoint { convert(event.locationInWindow, from: nil) }
}

private enum Drag {
    case none
    case newSelection(start: CGPoint)
    case move(original: CGRect, start: CGPoint)
    case resize(handle: Int, original: CGRect, start: CGPoint)
    case annotate(Annotation)
}

private enum Phase { case choosing, selected }

struct SessionConfig {
    var saveDirectory = "~/Pictures/Nivlet"
    var format = "png"
    var snapWindows = true
    var loupe = true
}

/// One capture from freeze to output. Owns the overlay windows and all editing state.
@MainActor
final class Session: NSObject, NSTextFieldDelegate {
    var onFinish: (_ event: [String: Any]) -> Void = { _ in }
    private let config: SessionConfig
    private let frozen: [FrozenScreen]
    private var windows: [OverlayWindow] = []
    private var views: [OverlayView] = []
    private let windowFrames: [CGRect]
    private let previousApp: NSRunningApplication?

    private var phase = Phase.choosing
    private var activeIndex: Int?
    private var selection: CGRect = .zero
    private var hover: (index: Int, rect: CGRect)?
    private var mouse: (index: Int, point: CGPoint)?
    private var drag = Drag.none

    private var tool: Tool?
    private var annotations: [Annotation] = []
    private var redoStack: [Annotation] = []
    private let toolbar = Toolbar()
    private let properties = PropertyBar()
    private var editor: NSTextField?
    private var editorPoint: CGPoint = .zero
    private var finished = false

    init(frozen: [FrozenScreen], config: SessionConfig) {
        self.frozen = frozen; self.config = config
        previousApp = NSWorkspace.shared.frontmostApplication
        windowFrames = config.snapWindows ? visibleWindowFrames(excludingPID: getpid()) : []
        super.init()
        toolbar.onAction = { [weak self] in self?.toolbarAction($0) }
        properties.onChange = { [weak self] in self?.applyProperties() }
    }

    func show() {
        for (i, f) in frozen.enumerated() {
            let w = OverlayWindow(screen: f.screen)
            let v = OverlayView(frozen: f, index: i); v.session = self
            w.contentView = v
            windows.append(w); views.append(v)
        }
        let mouseLocation = NSEvent.mouseLocation
        for (i, w) in windows.enumerated() {
            w.orderFrontRegardless()
            if frozen[i].screen.frame.contains(mouseLocation) {
                let p = CGPoint(x: mouseLocation.x - w.frame.minX, y: mouseLocation.y - w.frame.minY)
                mouse = (i, p); updateHover(i, p)
            }
        }
        if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
        let key = windows[mouse?.index ?? 0]
        key.makeKeyAndOrderFront(nil); key.makeFirstResponder(key.contentView)
        NSCursor.crosshair.set()
    }

    // MARK: Drawing

    func draw(in view: OverlayView) {
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        let bounds = view.bounds
        cg.interpolationQuality = .high
        cg.draw(view.frozen.image, in: bounds)

        let isActive = activeIndex == view.index && phase == .selected || isDraggingSelection && activeIndex == view.index
        let focus: CGRect? = isActive ? selection : (phase == .choosing && hover?.index == view.index ? hover?.rect : nil)
        let dim = NSBezierPath(rect: bounds)
        if let focus, !focus.isEmpty { dim.appendRect(focus); dim.windingRule = .evenOdd }
        NSColor.black.withAlphaComponent(0.42).setFill(); dim.fill()

        if isActive {
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(rect: selection).addClip()
            annotations.forEach { $0.draw(frozen: view.frozen.image, viewHeight: bounds.height, pixelScale: view.frozen.pixelScale) }
            if case .annotate(let a) = drag { a.draw(frozen: view.frozen.image, viewHeight: bounds.height, pixelScale: view.frozen.pixelScale) }
            NSGraphicsContext.restoreGraphicsState()
            drawSelectionChrome(selection, bounds: bounds, scale: view.frozen.pixelScale)
        } else if let focus, phase == .choosing {
            accentColor.setStroke()
            let p = NSBezierPath(rect: focus.insetBy(dx: 1, dy: 1)); p.lineWidth = 2; p.stroke()
        }
        if config.loupe, let mouse, mouse.index == view.index, showsLoupe { drawLoupe(view, at: mouse.point) }
    }

    private var isDraggingSelection: Bool {
        switch drag { case .newSelection, .move, .resize: return true; default: return false }
    }
    private var showsLoupe: Bool {
        if phase == .choosing { return true }
        switch drag { case .newSelection, .resize: return true; default: return false }
    }

    private func drawSelectionChrome(_ r: CGRect, bounds: CGRect, scale: CGFloat) {
        accentColor.setStroke()
        let border = NSBezierPath(rect: r.insetBy(dx: -0.75, dy: -0.75)); border.lineWidth = 1.5; border.stroke()
        if tool == nil || isDraggingSelection {
            for h in handleRects(r) {
                NSColor.white.setFill(); NSBezierPath(roundedRect: h, xRadius: 2, yRadius: 2).fill()
                accentColor.setStroke()
                let p = NSBezierPath(roundedRect: h, xRadius: 2, yRadius: 2); p.lineWidth = 1.5; p.stroke()
            }
        }
        let label = "\(Int(r.width.rounded())) × \(Int(r.height.rounded()))  ·  \(Int((r.width * scale).rounded())) × \(Int((r.height * scale).rounded())) px" as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium), .foregroundColor: NSColor.white]
        let size = label.size(withAttributes: attrs)
        var origin = CGPoint(x: r.minX, y: r.maxY + 6)
        if origin.y + size.height + 8 > bounds.maxY { origin = CGPoint(x: r.minX + 6, y: r.maxY - size.height - 12) }
        let box = CGRect(x: origin.x, y: origin.y, width: size.width + 14, height: size.height + 6)
        NSColor(white: 0.08, alpha: 0.82).setFill(); NSBezierPath(roundedRect: box, xRadius: 6, yRadius: 6).fill()
        label.draw(at: CGPoint(x: box.minX + 7, y: box.minY + 3), withAttributes: attrs)
    }

    private func handleRects(_ r: CGRect) -> [CGRect] {
        let xs = [r.minX, r.midX, r.maxX], ys = [r.minY, r.midY, r.maxY]
        var result: [CGRect] = []
        for (yi, y) in ys.enumerated() { for (xi, x) in xs.enumerated() where !(xi == 1 && yi == 1) {
            result.append(CGRect(x: x - 4.5, y: y - 4.5, width: 9, height: 9))
        } }
        return result
    }

    private func drawLoupe(_ view: OverlayView, at p: CGPoint) {
        let img = view.frozen.image, scale = view.frozen.pixelScale
        let px = Int(p.x * scale), py = Int((view.bounds.height - p.y) * scale)
        let cells = 15, zoom: CGFloat = 8
        guard let piece = img.cropping(to: CGRect(x: px - cells / 2, y: py - cells / 2, width: cells, height: cells)) else { return }
        let side = CGFloat(cells) * zoom, infoHeight: CGFloat = 58
        var box = CGRect(x: p.x + 22, y: p.y - 22 - side - infoHeight, width: side, height: side + infoHeight)
        if box.maxX > view.bounds.maxX - 6 { box.origin.x = p.x - 22 - side }
        if box.minY < 6 { box.origin.y = p.y + 22 }
        let outer = NSBezierPath(roundedRect: box, xRadius: 10, yRadius: 10)
        NSColor(white: 0.1, alpha: 0.94).setFill(); outer.fill()
        NSColor(white: 1, alpha: 0.16).setStroke(); outer.lineWidth = 1; outer.stroke()
        let grid = CGRect(x: box.minX, y: box.maxY - side, width: side, height: side)
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        cg.saveGState()
        NSBezierPath(roundedRect: grid, xRadius: 10, yRadius: 10).addClip()
        cg.interpolationQuality = .none; cg.draw(piece, in: grid)
        // Pixel grid makes the magnification readable even on flat colours.
        NSColor(white: 0.5, alpha: 0.18).setStroke()
        let lines = NSBezierPath(); lines.lineWidth = 0.5
        for i in 1..<cells {
            let o = CGFloat(i) * zoom
            lines.move(to: CGPoint(x: grid.minX + o, y: grid.minY)); lines.line(to: CGPoint(x: grid.minX + o, y: grid.maxY))
            lines.move(to: CGPoint(x: grid.minX, y: grid.minY + o)); lines.line(to: CGPoint(x: grid.maxX, y: grid.minY + o))
        }
        lines.stroke()
        cg.restoreGState()
        let center = CGRect(x: grid.midX - zoom / 2, y: grid.midY - zoom / 2, width: zoom, height: zoom)
        NSColor.black.setStroke(); let c1 = NSBezierPath(rect: center.insetBy(dx: -1.5, dy: -1.5)); c1.lineWidth = 1; c1.stroke()
        NSColor.white.setStroke(); let c2 = NSBezierPath(rect: center.insetBy(dx: -0.5, dy: -0.5)); c2.lineWidth = 1.2; c2.stroke()

        let color = pixelColor(piece, x: cells / 2, y: cells / 2)
        let swatch = CGRect(x: box.minX + 10, y: box.minY + 34, width: 14, height: 14)
        (color ?? .black).setFill(); NSBezierPath(roundedRect: swatch, xRadius: 3, yRadius: 3).fill()
        NSColor(white: 1, alpha: 0.35).setStroke(); let sw = NSBezierPath(roundedRect: swatch, xRadius: 3, yRadius: 3); sw.lineWidth = 1; sw.stroke()
        let strong: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 11.5, weight: .semibold), .foregroundColor: NSColor.white]
        let soft: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .regular), .foregroundColor: NSColor(white: 1, alpha: 0.62)]
        ((color?.hexString ?? "—") as NSString).draw(at: CGPoint(x: swatch.maxX + 7, y: swatch.minY - 1), withAttributes: strong)
        ("\(Int(p.x)), \(Int(view.bounds.height - p.y))" as NSString).draw(at: CGPoint(x: box.minX + 10, y: box.minY + 18), withAttributes: soft)
        (t("copyColorHint") as NSString).draw(at: CGPoint(x: box.minX + 10, y: box.minY + 4), withAttributes: soft)
    }

    private func pixelColor(_ image: CGImage, x: Int, y: Int) -> NSColor? {
        var data = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &data, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(image, in: CGRect(x: -CGFloat(x), y: -CGFloat(image.height - 1 - y), width: CGFloat(image.width), height: CGFloat(image.height)))
        return NSColor(srgbRed: CGFloat(data[0]) / 255, green: CGFloat(data[1]) / 255, blue: CGFloat(data[2]) / 255, alpha: 1)
    }

    private func redraw() { views.forEach { $0.needsDisplay = true } }

    // MARK: Mouse

    private func updateHover(_ index: Int, _ p: CGPoint) {
        let origin = frozen[index].screen.frame.origin
        let global = CGPoint(x: p.x + origin.x, y: p.y + origin.y)
        let bounds = CGRect(origin: .zero, size: frozen[index].screen.frame.size)
        if let w = windowFrames.first(where: { $0.contains(global) }) {
            hover = (index, w.offsetBy(dx: -origin.x, dy: -origin.y).intersection(bounds))
        } else {
            hover = (index, bounds)
        }
    }

    func mouseMoved(_ view: OverlayView, _ event: NSEvent) {
        let p = view.local(event)
        mouse = (view.index, p)
        if phase == .choosing { updateHover(view.index, p) }
        updateCursor(view, p)
        redraw()
    }

    private func updateCursor(_ view: OverlayView, _ p: CGPoint) {
        guard phase == .selected, activeIndex == view.index else { NSCursor.crosshair.set(); return }
        if toolbar.frame.contains(p) || (properties.superview != nil && properties.frame.contains(p)) { NSCursor.arrow.set(); return }
        if tool == nil, let h = handleRects(selection).firstIndex(where: { $0.insetBy(dx: -4, dy: -4).contains(p) }) {
            ([1, 6].contains(h) ? NSCursor.resizeUpDown : [3, 4].contains(h) ? NSCursor.resizeLeftRight : NSCursor.crosshair).set(); return
        }
        if tool == nil && selection.contains(p) { NSCursor.openHand.set(); return }
        if tool == .text && selection.contains(p) { NSCursor.iBeam.set(); return }
        NSCursor.crosshair.set()
    }

    func mouseDown(_ view: OverlayView, _ event: NSEvent) {
        let p = view.local(event)
        if editor != nil { commitText() }
        switch phase {
        case .choosing:
            activeIndex = view.index
            drag = .newSelection(start: p)
        case .selected:
            guard view.index == activeIndex else { return }
            if tool == nil, let h = handleRects(selection).firstIndex(where: { $0.insetBy(dx: -4, dy: -4).contains(p) }) {
                drag = .resize(handle: h, original: selection, start: p); hideBars()
            } else if selection.contains(p) {
                if event.clickCount == 2 && tool == nil { copyAndFinish(); return }
                if let tool {
                    if tool == .text {
                        // Clicking existing text edits it instead of stacking a new text on top.
                        if let index = annotations.lastIndex(where: { $0.tool == .text && $0.textBounds.insetBy(dx: -4, dy: -4).contains(p) }) {
                            let existing = annotations.remove(at: index)
                            redoStack.removeAll()
                            beginText(in: view, at: p, editing: existing)
                        } else {
                            beginText(in: view, at: p)
                        }
                        redraw()
                        return
                    }
                    let a = Annotation(tool: tool, color: palette[properties.colorIndex], width: strokeWidths[properties.sizeIndex], start: p)
                    a.mosaicMode = properties.mosaicMode; a.mosaicBlock = mosaicBlocks[properties.sizeIndex]
                    drag = .annotate(a)
                } else {
                    drag = .move(original: selection, start: p); hideBars(); NSCursor.closedHand.set()
                }
            } else if annotations.isEmpty && tool == nil {
                phase = .choosing; drag = .newSelection(start: p); hideBars()
            }
        }
        redraw()
    }

    func mouseDragged(_ view: OverlayView, _ event: NSEvent) {
        let p = view.local(event)
        mouse = (view.index, p)
        let bounds = view.bounds
        switch drag {
        case .newSelection(let start):
            guard view.index == activeIndex else { return }
            selection = CGRect(x: min(start.x, p.x), y: min(start.y, p.y), width: abs(p.x - start.x), height: abs(p.y - start.y)).intersection(bounds)
        case .move(let original, let start):
            var r = original.offsetBy(dx: p.x - start.x, dy: p.y - start.y)
            r.origin.x = min(max(0, r.minX), bounds.width - r.width)
            r.origin.y = min(max(0, r.minY), bounds.height - r.height)
            selection = r
        case .resize(let h, let original, let start):
            selection = resized(original, handle: h, dx: p.x - start.x, dy: p.y - start.y).intersection(bounds)
        case .annotate(let a):
            let clamped = CGPoint(x: min(max(p.x, selection.minX), selection.maxX), y: min(max(p.y, selection.minY), selection.maxY))
            if a.tool == .pen { a.points.append(clamped) } else { a.points[a.points.count - 1] = clamped }
            a.cachedMosaic = nil
        case .none: return
        }
        redraw()
    }

    func mouseUp(_ view: OverlayView, _ event: NSEvent) {
        switch drag {
        case .newSelection:
            if selection.width < 4 || selection.height < 4 { selection = hover?.index == view.index ? hover!.rect : view.bounds }
            phase = .selected; showBars()
        case .move, .resize:
            selection = selection.integral; showBars()
        case .annotate(let a):
            if a.isMeaningful { annotations.append(a); redoStack.removeAll() }
        case .none: break
        }
        drag = .none
        updateCursor(view, view.local(event))
        redraw()
    }

    func rightMouseDown(_ view: OverlayView) {
        if phase == .selected && annotations.isEmpty { resetToChoosing() } else if phase == .choosing { cancel() }
    }

    private func resized(_ r: CGRect, handle: Int, dx: CGFloat, dy: CGFloat) -> CGRect {
        // Handles are ordered bottom row (0,1,2), middle (3,4), top (5,6,7) in non-flipped coordinates.
        var minX = r.minX, maxX = r.maxX, minY = r.minY, maxY = r.maxY
        if [0, 3, 5].contains(handle) { minX += dx }
        if [2, 4, 7].contains(handle) { maxX += dx }
        if [0, 1, 2].contains(handle) { minY += dy }
        if [5, 6, 7].contains(handle) { maxY += dy }
        return CGRect(x: min(minX, maxX), y: min(minY, maxY), width: abs(maxX - minX), height: abs(maxY - minY))
    }

    private func resetToChoosing() {
        phase = .choosing; selection = .zero; annotations.removeAll(); redoStack.removeAll(); tool = nil
        hideBars(); toolbar.select(nil)
        if let mouse { updateHover(mouse.index, mouse.point) }
        redraw()
    }

    // MARK: Toolbar

    private func showBars() {
        guard let i = activeIndex else { return }
        let view = views[i]
        if toolbar.superview !== view { view.addSubview(toolbar) }
        if let tool { properties.configure(for: tool); if properties.superview !== view { view.addSubview(properties) } } else { properties.removeFromSuperview() }
        let gap: CGFloat = 8, bounds = view.bounds
        let extra = properties.superview != nil ? properties.frame.height + 6 : 0
        let block = toolbar.frame.height + extra
        let x = min(max(4, selection.maxX - toolbar.frame.width), bounds.width - toolbar.frame.width - 4)
        var y: CGFloat
        var barsBelow = true
        if selection.minY - gap - block >= 4 { y = selection.minY - gap - toolbar.frame.height }
        else if selection.maxY + gap + block <= bounds.maxY - 4 { y = selection.maxY + gap; barsBelow = false }
        else { y = selection.minY + gap + extra; barsBelow = true }
        toolbar.setFrameOrigin(CGPoint(x: x, y: y))
        if properties.superview != nil {
            let px = min(max(4, toolbar.frame.minX), bounds.width - properties.frame.width - 4)
            let py = barsBelow ? toolbar.frame.minY - 6 - properties.frame.height : toolbar.frame.maxY + 6
            properties.setFrameOrigin(CGPoint(x: px, y: py))
        }
        toolbar.isHidden = false; properties.isHidden = false
    }

    private func hideBars() { toolbar.isHidden = true; properties.isHidden = true }

    private func toolbarAction(_ action: ToolbarAction) {
        switch action {
        case .tool(let t): setTool(tool == t ? nil : t)
        case .undo: undo()
        case .redo: redo()
        case .save: saveAndFinish()
        case .cancel: cancel()
        case .copy: copyAndFinish()
        }
    }

    private func setTool(_ t: Tool?) {
        if editor != nil { commitText() }
        tool = t; toolbar.select(t); showBars(); redraw()
    }

    private func applyProperties() { showBars() }

    private func undo() { if let a = annotations.popLast() { redoStack.append(a); redraw() } }
    private func redo() { if let a = redoStack.popLast() { annotations.append(a); redraw() } }

    // MARK: Text

    private var editorColor = palette[0]
    private var editorSize: CGFloat = 18

    private func beginText(in view: OverlayView, at p: CGPoint, editing existing: Annotation? = nil) {
        let size = existing?.fontSize ?? textSizes[properties.sizeIndex]
        let color = existing?.color ?? palette[properties.colorIndex]
        let origin = existing?.points[0] ?? CGPoint(x: p.x, y: p.y - size * 0.55)
        let field = NSTextField(string: existing?.text ?? "")
        field.isBordered = false; field.drawsBackground = false; field.focusRingType = .none
        field.font = .systemFont(ofSize: size, weight: .semibold)
        field.textColor = color
        field.delegate = self
        field.cell?.isScrollable = true
        field.cell?.usesSingleLineMode = true
        // A dashed outline shows where typing goes, so new text is not placed on top of old text by mistake.
        field.wantsLayer = true
        let outline = CAShapeLayer()
        outline.fillColor = nil; outline.strokeColor = accentColor.cgColor; outline.lineWidth = 1; outline.lineDashPattern = [4, 3]
        field.layer?.addSublayer(outline)
        editorOutline = outline
        editorColor = color; editorSize = size; editorPoint = origin
        view.addSubview(field)
        editor = field
        resizeEditor()
        view.window?.makeFirstResponder(field)
        field.currentEditor()?.selectedRange = NSRange(location: field.stringValue.utf16.count, length: 0)
    }
    private var editorOutline: CAShapeLayer?

    private func resizeEditor() {
        guard let field = editor else { return }
        let text = field.stringValue.isEmpty ? "  " : field.stringValue
        let width = max(80, (text as NSString).size(withAttributes: [.font: field.font!]).width + 18)
        let height = ceil(editorSize * 1.45)
        field.frame = CGRect(x: editorPoint.x - 4, y: editorPoint.y - height * 0.2, width: width, height: height)
        editorOutline?.frame = field.bounds
        editorOutline?.path = CGPath(roundedRect: field.bounds.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 3, cornerHeight: 3, transform: nil)
    }

    func controlTextDidChange(_ obj: Notification) { resizeEditor() }

    private func commitText() {
        guard let field = editor else { return }
        let a = Annotation(tool: .text, color: editorColor, width: 0, start: editorPoint)
        a.text = field.stringValue; a.fontSize = editorSize
        if a.isMeaningful { annotations.append(a); redoStack.removeAll() }
        field.removeFromSuperview(); editor = nil; editorOutline = nil
        if let i = activeIndex { windows[i].makeFirstResponder(views[i]) }
        redraw()
    }

    private func cancelText() {
        editor?.removeFromSuperview(); editor = nil
        if let i = activeIndex { windows[i].makeFirstResponder(views[i]) }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) { commitText(); return true }
        if selector == #selector(NSResponder.cancelOperation(_:)) { cancelText(); return true }
        return false
    }

    // MARK: Keyboard

    /// Esc leaves the capture at once. Stepping back to window choosing looked like a second,
    /// duplicate selection; reselecting is done with a right-click instead.
    func escape() {
        if editor != nil { cancelText(); return }
        cancel()
    }

    func keyDown(_ event: NSEvent) -> Bool {
        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        switch event.keyCode {
        case 53: escape(); return true
        case 36, 76: if phase == .selected { copyAndFinish() }; return true
        case 123, 124, 125, 126: nudge(event.keyCode, mods); return true
        default: break
        }
        if mods == .command {
            switch key {
            case "c": if phase == .selected { copyAndFinish() } else { copyColor() }; return true
            case "s": if phase == .selected { saveAndFinish() }; return true
            case "z": undo(); return true
            case "w": cancel(); return true
            default: return false
            }
        }
        if mods == [.command, .shift] && key == "z" { redo(); return true }
        guard mods.isEmpty else { return false }
        if phase == .choosing && key == "c" { copyColor(); return true }
        guard phase == .selected else { return false }
        let shortcuts: [String: Tool] = ["r": .rect, "a": .arrow, "b": .pen, "t": .text, "m": .mosaic]
        if let t = shortcuts[key] { setTool(tool == t ? nil : t); return true }
        if let n = Int(key), (1...palette.count).contains(n) { properties.colorIndex = n - 1; showBars(); return true }
        return false
    }

    private func nudge(_ code: UInt16, _ mods: NSEvent.ModifierFlags) {
        guard phase == .selected, let i = activeIndex else { return }
        let step: CGFloat = mods.contains(.shift) ? 10 : 1
        let bounds = views[i].bounds
        var r = selection
        if mods.contains(.command) {
            switch code {
            case 124: r.size.width += step
            case 123: r.size.width = max(1, r.width - step)
            case 125: r.origin.y -= step; r.size.height += step
            default: if r.height > step { r.origin.y += step; r.size.height -= step }
            }
        } else {
            switch code {
            case 123: r.origin.x -= step
            case 124: r.origin.x += step
            case 125: r.origin.y -= step
            default: r.origin.y += step
            }
            r.origin.x = min(max(0, r.minX), bounds.width - r.width)
            r.origin.y = min(max(0, r.minY), bounds.height - r.height)
        }
        selection = r.intersection(bounds); showBars(); redraw()
    }

    private func copyColor() {
        guard let mouse else { return }
        let v = views[mouse.index], scale = v.frozen.pixelScale
        let px = Int(mouse.point.x * scale), py = Int((v.bounds.height - mouse.point.y) * scale)
        guard let piece = v.frozen.image.cropping(to: CGRect(x: px, y: py, width: 1, height: 1)), let color = pixelColor(piece, x: 0, y: 0) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(color.hexString, forType: .string)
        finish(["event": "color", "value": color.hexString])
    }

    // MARK: Output

    private func render() -> CGImage? {
        guard let i = activeIndex, !selection.isEmpty else { return nil }
        let f = frozen[i], view = views[i], scale = f.pixelScale
        let crop = CGRect(x: selection.minX * scale, y: (view.bounds.height - selection.maxY) * scale,
                          width: selection.width * scale, height: selection.height * scale).integral
        guard let piece = f.image.cropping(to: crop),
              let ctx = CGContext(data: nil, width: Int(crop.width), height: Int(crop.height), bitsPerComponent: 8, bytesPerRow: 0,
                                  space: f.image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.draw(piece, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
        if !annotations.isEmpty {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
            ctx.scaleBy(x: crop.width / selection.width, y: crop.height / selection.height)
            ctx.translateBy(x: -selection.minX, y: -selection.minY)
            annotations.forEach { $0.draw(frozen: f.image, viewHeight: view.bounds.height, pixelScale: scale) }
            NSGraphicsContext.restoreGraphicsState()
        }
        return ctx.makeImage()
    }

    private func copyAndFinish() {
        if editor != nil { commitText() }
        guard let image = render() else { return }
        guard ClipboardWriter.write(image) else { finish(["event": "error", "message": "copy"]); return }
        finish(["event": "copied", "width": image.width, "height": image.height])
    }

    private func saveAndFinish() {
        if editor != nil { commitText() }
        guard let image = render() else { return }
        do {
            let url = try FileSaver.save(image, directory: config.saveDirectory, format: config.format)
            finish(["event": "saved", "path": url.path, "width": image.width, "height": image.height])
        } catch {
            finish(["event": "error", "message": "save", "detail": error.localizedDescription])
        }
    }

    func cancel() { finish(["event": "cancelled"]) }

    #if NIVLET_SELFTEST
    var testView: OverlayView? { views.first }
    func testSelect(_ r: CGRect, index: Int) { activeIndex = index; selection = r; phase = .selected; showBars(); redraw() }
    func testAnnotate(_ list: [Annotation]) { annotations = list; redraw() }
    /// Selects the text tool and clicks the existing text so the editor and property bar are visible.
    func testShowTextEditing(in view: OverlayView, at p: CGPoint) {
        setTool(.text)
        if let index = annotations.lastIndex(where: { $0.tool == .text && $0.textBounds.insetBy(dx: -4, dy: -4).contains(p) }) {
            let existing = annotations.remove(at: index)
            beginText(in: view, at: p, editing: existing)
        }
        redraw()
    }
    func testSaveRender(to path: String) {
        let hold = Double(ProcessInfo.processInfo.environment["NIVLET_SELFTEST_HOLD"] ?? "") ?? 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) { [self] in
            if editor != nil { commitText() }
            guard let image = render(), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { finish(["event": "error", "message": "selftest"]); return }
            try? data.write(to: URL(fileURLWithPath: path))
            finish(["event": "selftest", "width": image.width, "height": image.height, "copied": ClipboardWriter.write(image)])
        }
    }
    #endif

    private func finish(_ event: [String: Any]) {
        guard !finished else { return }
        finished = true
        windows.forEach { $0.orderOut(nil) }
        views.forEach { $0.session = nil }
        windows.removeAll(); views.removeAll()
        previousApp?.activate()
        onFinish(event)
    }
}
