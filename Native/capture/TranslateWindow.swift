import AppKit

/// Floating translation card for selected text. It does not activate Nivlet, so the app you were
/// in stays active; clicking elsewhere or Esc closes it unless pinned. Styling matches the capture
/// toolbar and result panel (Nivlet palette, light and dark, interface language).
final class TranslatePanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 360, height: 120), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isOpaque = false; backgroundColor = .clear; hasShadow = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
    }
    override func cancelOperation(_ sender: Any?) { (contentView as? TranslateCard)?.onClose() }
}

struct TranslateRequest {
    var text: String
    var anchor: NSPoint          // global Cocoa coordinates, just below the selection
    var mode: String             // "auto" or a fixed target language
    var remembered: [String: String]
    var showSource: Bool
    var autoCopy: Bool
    var editable: Bool           // the selection is in an editable field, so Replace is offered
    var interface: String
}

@MainActor
final class TranslateCard: NSView {
    var onClose: () -> Void = {}
    var onEvent: ([String: Any]) -> Void = { _ in }
    private let background = makeHUD()
    private let stack = NSStackView()
    private let width: CGFloat = 360
    private var request: TranslateRequest!
    private var source = "en", target = "zh-Hans"
    private var result = ""
    private var token = 0
    private(set) var pinned = false
    private var pinButton: ToolButton?

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 360, height: 100))
        addSubview(background)
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 14, bottom: 12, right: 10)
        background.addSubview(stack)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { true }

    func start(_ request: TranslateRequest) {
        self.request = request
        source = Direction.detect(request.text)
        target = Direction.target(source: source, mode: request.mode, remembered: request.remembered)
        result = ""
        render(state: .working)
        translate()
    }

    private enum State { case working, partial, done, failed(String) }

    /// Detection can confidently pick a language system translation lacks (garbled OCR often reads
    /// as Hungarian). Latin-script text then falls back to English once before giving up.
    private func retryAsEnglish() -> Bool {
        guard source != "en", !source.hasPrefix("zh"), !["ja", "ko"].contains(source),
              !request.text.unicodeScalars.contains(where: { $0.value >= 0x3040 }) else { return false }
        source = "en"
        target = Direction.target(source: source, mode: request.mode, remembered: request.remembered)
        render(state: .working)
        translate()
        return true
    }

    private func translate() {
        token += 1
        let current = token
        guard #available(macOS 15.0, *) else { render(state: .failed(t("needsMacOS15"))); return }
        let text = request.text, from = source, to = target
        let lines = text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if lines.count > 1 {
            Task { @MainActor in
                var parts = [String?](repeating: nil, count: lines.count)
                let started = Date()
                do {
                    try await SystemTranslator.shared.translateLines(lines, from: from, to: to) { index, line in
                        guard current == self.token else { return }
                        if index < 0 { parts = [line] } else if parts.indices.contains(index) { parts[index] = line }
                        self.result = parts.compactMap { $0 }.joined(separator: "\n")
                        self.render(state: parts.contains(where: { $0 == nil }) ? .partial : .done)
                    }
                    guard current == token else { return }
                    onEvent(["event": "translated", "ms": Int(Date().timeIntervalSince(started) * 1000), "lines": lines.count])
                    render(state: .done)
                    if request.autoCopy { copy(result, flash: nil) }
                } catch {
                    guard current == token else { return }
                    if (error as? TranslateError) == .unsupported, retryAsEnglish() { return }
                    render(state: .failed((error as? TranslateError) == .unsupported ? t("pairUnsupported") : t("translateFailed")))
                }
            }
            return
        }
        Task { @MainActor in
            do {
                let started = Date()
                let translated = try await SystemTranslator.shared.translate(text, from: from, to: to)
                let timing = SystemTranslator.shared.lastTiming
                onEvent(["event": "translated", "ms": Int(Date().timeIntervalSince(started) * 1000), "checkMs": timing.check, "translateMs": timing.translate])
                guard current == token else { return }
                result = translated
                render(state: .done)
                if request.autoCopy { copy(result, flash: nil) }
            } catch {
                guard current == token else { return }
                if (error as? TranslateError) == .unsupported, retryAsEnglish() { return }
                render(state: .failed((error as? TranslateError) == .unsupported ? t("pairUnsupported") : t("translateFailed")))
            }
        }
    }

    private func render(state: State) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        // Header: direction menu, pin, close.
        let header = NSStackView(); header.orientation = .horizontal; header.spacing = 4
        let direction = FlatButton(title: "\(languageName(source, interface: request.interface)) → \(languageName(target, interface: request.interface))  ▾", target: self, action: #selector(showDirectionMenu(_:)))
        header.addArrangedSubview(direction)
        let spacer = NSView(); spacer.setContentHuggingPriority(.defaultLow, for: .horizontal); header.addArrangedSubview(spacer)
        let pin = ToolButton(symbol: "pin", tooltip: t("pinCard"), target: self, action: #selector(togglePin))
        pin.selectedState = pinned; pinButton = pin
        header.addArrangedSubview(pin)
        header.addArrangedSubview(ToolButton(symbol: "xmark", tooltip: t("close"), target: self, action: #selector(closePressed)))
        add(header, inset: 0)

        if request.showSource {
            let src = NSTextField(wrappingLabelWithString: request.text)
            src.font = .systemFont(ofSize: 12.5); src.textColor = .secondaryLabelColor
            src.maximumNumberOfLines = 4; src.lineBreakMode = .byWordWrapping; src.isSelectable = true
            src.cell?.truncatesLastVisibleLine = true
            add(src)
        }
        switch state {
        case .working:
            let note = NSTextField(labelWithString: t("translating")); note.font = .systemFont(ofSize: 14); note.textColor = .secondaryLabelColor
            add(note)
        case .failed(let message):
            let note = NSTextField(wrappingLabelWithString: message); note.font = .systemFont(ofSize: 13); note.textColor = .secondaryLabelColor
            add(note)
            let row = NSStackView(); row.spacing = 8
            row.addArrangedSubview(FlatButton(title: t("openLanguageSettings"), target: self, action: #selector(openSettings)))
            add(row)
        case .partial:
            let out = NSTextField(wrappingLabelWithString: result + "\n…")
            out.font = .systemFont(ofSize: 15); out.textColor = .labelColor; out.isSelectable = true
            add(out)
        case .done:
            let out = NSTextField(wrappingLabelWithString: result)
            out.font = .systemFont(ofSize: 15); out.textColor = .labelColor; out.isSelectable = true
            add(out)
            let row = NSStackView(); row.spacing = 8
            if request.editable { row.addArrangedSubview(FlatButton(title: t("replaceSource"), target: self, action: #selector(replacePressed))) }
            let gap = NSView(); gap.setContentHuggingPriority(.defaultLow, for: .horizontal); row.addArrangedSubview(gap)
            row.addArrangedSubview(FlatButton(title: t("copySource"), target: self, action: #selector(copySourcePressed(_:))))
            row.addArrangedSubview(PrimaryButton(title: t("copyTranslation"), target: self, action: #selector(copyResultPressed(_:))))
            add(row, inset: 4)
        }
        layoutCard()
    }

    private func add(_ view: NSView, inset: CGFloat = 4) {
        stack.addArrangedSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: width - 24 - inset).isActive = true
    }

    private func layoutCard() {
        stack.translatesAutoresizingMaskIntoConstraints = true
        stack.frame = NSRect(x: 0, y: 0, width: width, height: 10)
        stack.layoutSubtreeIfNeeded()
        let size = NSSize(width: width, height: stack.fittingSize.height)
        guard let window else { frame.size = size; background.frame = bounds; stack.frame = background.bounds; return }
        // Keep the top edge where it is while the content grows.
        var f = window.frame
        f.origin.y += f.height - size.height
        f.size = size
        window.setFrame(f, display: true)
        frame = NSRect(origin: .zero, size: size)
        background.frame = bounds; stack.frame = background.bounds
    }

    @objc private func showDirectionMenu(_ sender: NSButton) {
        let menu = NSMenu()
        for code in translationTargets where Direction.family(code) != Direction.family(source) {
            let item = MenuAction(title: languageName(code, interface: request.interface), key: "") { [weak self] in self?.choose(code) }
            item.state = code == target ? .on : .off
            menu.addItem(item)
        }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }

    private func choose(_ code: String) {
        target = code
        onEvent(["event": "directionChosen", "source": source, "target": code])
        result = ""
        render(state: .working)
        translate()
    }

    @objc private func togglePin() { pinned.toggle(); pinButton?.selectedState = pinned }
    @objc private func closePressed() { onClose() }
    @objc private func openSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension")!)
    }
    @objc private func copySourcePressed(_ sender: NSButton) { copy(request.text, flash: sender) }
    @objc private func copyResultPressed(_ sender: NSButton) { copy(result, flash: sender) }
    @objc private func replacePressed() {
        onEvent(["event": "replaceSelection", "text": result])
        onClose()
    }

    private func copy(_ text: String, flash sender: NSButton?) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        onEvent(["event": "textCopied"])
        guard let sender else { return }
        let original = sender.attributedTitle
        sender.attributedTitle = NSAttributedString(string: t("copied"), attributes: original.attributes(at: 0, effectiveRange: nil))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { sender.attributedTitle = original }
    }
}

/// Shows one translation card at a time and closes it on outside clicks unless it is pinned.
@MainActor
final class TranslateController {
    static let shared = TranslateController()
    var emit: ([String: Any]) -> Void = { _ in }
    private var window: TranslatePanelWindow?
    private var card: TranslateCard?
    private var monitor: Any?

    func show(_ request: TranslateRequest) {
        close()
        let window = TranslatePanelWindow()
        let card = TranslateCard()
        card.onClose = { [weak self] in self?.close() }
        card.onEvent = { [weak self] in self?.emit($0) }
        window.contentView = card
        card.start(request)
        // Place below the selection, flipped above it or clamped when it would leave the screen.
        let size = card.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(request.anchor) } ?? NSScreen.main ?? NSScreen.screens[0]
        let visible = screen.visibleFrame
        var origin = NSPoint(x: request.anchor.x, y: request.anchor.y - 8 - size.height)
        if origin.y < visible.minY + 6 { origin.y = min(visible.maxY - size.height - 6, request.anchor.y + 28) }
        origin.x = min(max(visible.minX + 6, origin.x), visible.maxX - size.width - 6)
        window.setFrame(NSRect(origin: origin, size: size), display: false)
        window.orderFrontRegardless()
        window.makeKey()
        self.window = window; self.card = card
        // Mouse-down monitors outside our own windows need no extra permission.
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let card = self.card, !card.pinned else { return }
                self.close()
            }
        }
    }

    func close() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        window?.orderOut(nil)
        window = nil; card = nil
    }
}
