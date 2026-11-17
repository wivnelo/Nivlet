import AppKit

/// A screenshot or clipboard image pinned above other windows. Drag to move, scroll to zoom,
/// Option-scroll for opacity, double-click or Esc to close, right-click for the menu.
final class PinWindow: NSPanel {
    override var canBecomeKey: Bool { true }

    init(image: CGImage, frame: NSRect) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false; backgroundColor = .clear; hasShadow = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
    }
}

@MainActor
final class PinView: NSView {
    let image: CGImage
    /// Size in points at 100 %.
    let naturalSize: NSSize
    var zoom: CGFloat = 1
    var onClose: () -> Void = {}
    var onCloseAll: () -> Void = {}
    var onCopy: () -> Void = {}
    var onSave: () -> Void = {}
    private let badge = NSTextField(labelWithString: "")
    private var badgeTimer: Timer?

    init(image: CGImage, naturalSize: NSSize) {
        self.image = image; self.naturalSize = naturalSize
        super.init(frame: NSRect(origin: .zero, size: naturalSize))
        wantsLayer = true
        layer?.cornerRadius = 3
        layer?.masksToBounds = true
        badge.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        badge.textColor = .white
        badge.drawsBackground = true; badge.backgroundColor = NSColor(white: 0.1, alpha: 0.78)
        badge.isBezeled = false; badge.alignment = .center
        badge.wantsLayer = true; badge.layer?.cornerRadius = 5
        badge.isHidden = true
        addSubview(badge)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }
    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { true }
    private var hovered = false { didSet { needsDisplay = true } }
    override func mouseEntered(with event: NSEvent) { hovered = true }
    override func mouseExited(with event: NSEvent) { hovered = false }

    override func draw(_ dirtyRect: NSRect) {
        guard let cg = NSGraphicsContext.current?.cgContext else { return }
        cg.interpolationQuality = zoom < 1 ? .high : .medium
        cg.draw(image, in: bounds)
        // A thin outline shows the pin's edge on any background; blue while focused or hovered.
        let active = hovered || window?.isKeyWindow == true
        (active ? accentColor : NSColor(white: 0.5, alpha: 0.45)).setStroke()
        let edge = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)); edge.lineWidth = active ? 1.5 : 1; edge.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        if event.clickCount == 2 { onClose(); return }
        super.mouseDown(with: event)
    }

    override func scrollWheel(with event: NSEvent) {
        let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY * 0.01 : event.scrollingDeltaY * 0.08
        guard delta != 0, let window else { return }
        if event.modifierFlags.contains(.option) {
            window.alphaValue = min(1, max(0.2, window.alphaValue + delta))
            showBadge("\(t("opacity")) \(Int((window.alphaValue * 100).rounded()))%")
        } else {
            setZoom(zoom * (1 + delta), anchor: NSEvent.mouseLocation)
        }
    }

    /// Resizes around a screen point so the content under the cursor stays put.
    func setZoom(_ value: CGFloat, anchor: NSPoint? = nil) {
        guard let window else { return }
        let newZoom = min(5, max(0.1, value))
        let old = window.frame
        let size = NSSize(width: (naturalSize.width * newZoom).rounded(), height: (naturalSize.height * newZoom).rounded())
        let a = anchor ?? NSPoint(x: old.midX, y: old.midY)
        let fx = old.width > 0 ? (a.x - old.minX) / old.width : 0.5
        let fy = old.height > 0 ? (a.y - old.minY) / old.height : 0.5
        let frame = NSRect(x: a.x - size.width * fx, y: a.y - size.height * fy, width: size.width, height: size.height)
        zoom = newZoom
        window.setFrame(frame, display: true)
        showBadge("\(Int((zoom * 100).rounded()))%")
    }

    private func showBadge(_ text: String) {
        badge.stringValue = text
        badge.sizeToFit()
        let size = NSSize(width: badge.frame.width + 14, height: 20)
        badge.frame = NSRect(x: bounds.maxX - size.width - 6, y: 6, width: size.width, height: size.height)
        badge.isHidden = false
        badgeTimer?.invalidate()
        badgeTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.badge.isHidden = true }
        }
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        if !badge.isHidden { badge.setFrameOrigin(NSPoint(x: bounds.maxX - badge.frame.width - 6, y: 6)) }
    }

    override func keyDown(with event: NSEvent) {
        let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        if event.keyCode == 53 { onClose(); return }
        if mods == .command {
            switch key {
            case "w": onClose(); return
            case "c": onCopy(); showBadge(t("copied")); return
            case "s": onSave(); return
            case "0": setZoom(1); return
            case "=", "+": setZoom(zoom * 1.25); return
            case "-": setZoom(zoom / 1.25); return
            default: break
            }
        }
        if mods == [.command, .option] && key == "w" { onCloseAll(); return }
        super.keyDown(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        func item(_ title: String, _ key: String = "", _ mods: NSEvent.ModifierFlags = .command, _ action: @escaping () -> Void) -> NSMenuItem {
            let i = MenuAction(title: title, key: key, action: action); i.keyEquivalentModifierMask = mods; return i
        }
        menu.addItem(item(t("copy"), "c") { [weak self] in self?.onCopy() })
        menu.addItem(item(t("save"), "s") { [weak self] in self?.onSave() })
        menu.addItem(.separator())
        let opacity = NSMenuItem(title: t("opacity"), action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for value in [100, 80, 60, 40] {
            let i = item("\(value)%") { [weak self] in self?.window?.alphaValue = CGFloat(value) / 100 }
            i.state = Int(((window?.alphaValue ?? 1) * 100).rounded()) == value ? .on : .off
            sub.addItem(i)
        }
        opacity.submenu = sub
        menu.addItem(opacity)
        menu.addItem(item(t("actualSize"), "0") { [weak self] in self?.setZoom(1) })
        menu.addItem(.separator())
        menu.addItem(item(t("close"), "w") { [weak self] in self?.onClose() })
        menu.addItem(item(t("closeAllPins"), "w", [.command, .option]) { [weak self] in self?.onCloseAll() })
        return menu
    }
}

/// Menu item that runs a closure.
final class MenuAction: NSMenuItem {
    private let run: () -> Void
    init(title: String, key: String, action: @escaping () -> Void) {
        run = action
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
    }
    required init(coder: NSCoder) { fatalError() }
    @objc private func fire() { run() }
}

/// Owns every pin. Pins live as long as the helper, which runs while the screenshot module is on.
@MainActor
final class PinManager {
    static let shared = PinManager()
    var saveDirectory = "~/Pictures/Nivlet"
    var format = "png"
    var emit: ([String: Any]) -> Void = { _ in }
    private var windows: [PinWindow] = []

    /// `frame` is where the image sat on screen (global coordinates); nil centres it on the cursor.
    func pin(_ image: CGImage, pointSize: NSSize, at frame: NSRect? = nil) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(frame?.origin ?? mouse) } ?? NSScreen.main ?? NSScreen.screens[0]
        let visible = screen.visibleFrame
        // Large images start scaled down to fit 80 % of the screen; zoom back with ⌘0.
        let fit = min(1, visible.width * 0.8 / pointSize.width, visible.height * 0.8 / pointSize.height)
        let size = NSSize(width: (pointSize.width * fit).rounded(), height: (pointSize.height * fit).rounded())
        var rect = frame.map { NSRect(origin: $0.origin, size: size) } ?? NSRect(x: mouse.x - size.width / 2, y: mouse.y - size.height / 2, width: size.width, height: size.height)
        rect.origin.x = min(max(visible.minX, rect.minX), visible.maxX - rect.width)
        rect.origin.y = min(max(visible.minY, rect.minY), visible.maxY - rect.height)

        let window = PinWindow(image: image, frame: rect)
        let view = PinView(image: image, naturalSize: pointSize)
        view.zoom = fit
        view.onClose = { [weak self, weak window] in if let window { self?.close(window) } }
        view.onCloseAll = { [weak self] in self?.closeAll() }
        view.onCopy = { [weak self] in
            if ClipboardWriter.write(image, scale: CGFloat(image.width) / pointSize.width) { self?.emit(["event": "copied", "width": image.width, "height": image.height]) }
        }
        view.onSave = { [weak self] in
            guard let self else { return }
            do {
                let url = try FileSaver.save(image, directory: saveDirectory, format: format, scale: CGFloat(image.width) / pointSize.width)
                emit(["event": "saved", "path": url.path])
            } catch { emit(["event": "error", "message": "save"]) }
        }
        window.contentView = view
        windows.append(window)
        window.orderFrontRegardless()
        window.makeKey()
        emit(["event": "pinned", "count": windows.count])
    }

    /// Pins the image on the clipboard, if there is one.
    func pinClipboard() {
        guard let data = NSPasteboard.general.data(forType: .png) ?? NSPasteboard.general.data(forType: .tiff),
              let rep = NSBitmapImageRep(data: data), let image = rep.cgImage else {
            emit(["event": "error", "message": "noImage"]); return
        }
        pin(image, pointSize: pointSize(rep))
    }

    /// Pins an image file written by Nivlet (clipboard history), then removes the file.
    /// `size` is the on-screen size in points when Nivlet knows it (its image export drops the DPI).
    func pinFile(_ path: String, size: NSSize? = nil) {
        defer { try? FileManager.default.removeItem(atPath: path) }
        guard let data = FileManager.default.contents(atPath: path), let rep = NSBitmapImageRep(data: data), let image = rep.cgImage else {
            emit(["event": "error", "message": "noImage"]); return
        }
        pin(image, pointSize: size ?? pointSize(rep))
    }

    /// Point size from the image's DPI: Nivlet screenshots carry 144 dpi on Retina; ordinary 72 dpi
    /// images show one pixel per point.
    private func pointSize(_ rep: NSBitmapImageRep) -> NSSize {
        rep.size.width > 0 ? rep.size : NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    }

    func close(_ window: PinWindow) {
        window.orderOut(nil)
        windows.removeAll { $0 === window }
    }

    func closeAll() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}
