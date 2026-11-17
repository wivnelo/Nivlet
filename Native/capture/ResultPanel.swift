import AppKit

let secondaryFill = dynamicColor(light: NSColor(srgbRed: 0.93, green: 0.93, blue: 0.95, alpha: 1), dark: NSColor(srgbRed: 0.27, green: 0.27, blue: 0.29, alpha: 1))
let fieldFill = dynamicColor(light: NSColor(srgbRed: 0.97, green: 0.97, blue: 0.98, alpha: 1), dark: NSColor(srgbRed: 0.12, green: 0.12, blue: 0.13, alpha: 1))

/// Quiet secondary button that sits beside the blue primary one.
final class FlatButton: NSButton {
    override var wantsUpdateLayer: Bool { true }
    convenience init(title: String, target: AnyObject, action: Selector) {
        self.init(frame: .zero)
        isBordered = false
        self.target = target; self.action = action
        wantsLayer = true
        layer?.cornerRadius = 7
        attributedTitle = NSAttributedString(string: title, attributes: [.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 12.5, weight: .medium)])
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 28).isActive = true
    }
    override var intrinsicContentSize: NSSize {
        let base = super.intrinsicContentSize
        return NSSize(width: base.width + 24, height: 28)
    }
    override func updateLayer() { layer?.backgroundColor = secondaryFill.cgColor }
}

/// Panel next to the selection that shows recognised text or QR codes.
@MainActor
final class ResultPanel: NSView {
    enum Content { case working(String), message(String), text([String]), codes([Recognition.Code]) }

    var onCopy: (_ text: String, _ close: Bool) -> Void = { _, _ in }
    var onOpen: (URL) -> Void = { _ in }
    var onClose: () -> Void = {}
    private let background = makeHUD()
    private let stack = NSStackView()
    private var textView: NSTextView?
    private var payloads: [String] = []
    private let width: CGFloat = 320

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 80))
        addSubview(background)
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        background.addSubview(stack)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private(set) var isWorking = false

    func show(title: String, content: Content) {
        if case .working = content { isWorking = true } else { isWorking = false }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        textView = nil; payloads = []
        let header = NSStackView()
        header.orientation = .horizontal
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 12.5, weight: .semibold)
        let spacer = NSView(); spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let close = ToolButton(symbol: "xmark", tooltip: t("close"), target: self, action: #selector(closePressed))
        header.addArrangedSubview(label); header.addArrangedSubview(spacer); header.addArrangedSubview(close)
        add(header)

        switch content {
        case .working(let message), .message(let message):
            let note = NSTextField(wrappingLabelWithString: message)
            note.font = .systemFont(ofSize: 12.5); note.textColor = .secondaryLabelColor
            add(note)
        case .text(let lines):
            let scroll = NSScrollView()
            scroll.hasVerticalScroller = true; scroll.borderType = .noBorder
            // A filled field reads as editable in both themes; the bare border was nearly invisible on dark.
            scroll.drawsBackground = true; scroll.backgroundColor = fieldFill
            scroll.wantsLayer = true; scroll.layer?.cornerRadius = 7; scroll.layer?.borderWidth = 1; scroll.layer?.borderColor = barBorder.cgColor
            let view = NSTextView()
            view.string = lines.joined(separator: "\n")
            view.font = .systemFont(ofSize: 13); view.textColor = .labelColor
            view.drawsBackground = false; view.isRichText = false; view.allowsUndo = true
            view.textContainerInset = NSSize(width: 6, height: 6)
            view.isVerticallyResizable = true; view.autoresizingMask = [.width]
            view.textContainer?.widthTracksTextView = true
            scroll.documentView = view
            let lineHeight: CGFloat = 19
            let height = min(200, max(64, CGFloat(lines.count) * lineHeight + 16))
            scroll.translatesAutoresizingMaskIntoConstraints = false
            scroll.heightAnchor.constraint(equalToConstant: height).isActive = true
            add(scroll)
            textView = view
            let buttons = NSStackView(); buttons.spacing = 8
            buttons.addArrangedSubview(FlatButton(title: t("joinLines"), target: self, action: #selector(joinLines)))
            let gap = NSView(); gap.setContentHuggingPriority(.defaultLow, for: .horizontal); buttons.addArrangedSubview(gap)
            buttons.addArrangedSubview(FlatButton(title: t("copy"), target: self, action: #selector(copyText(_:))))
            buttons.addArrangedSubview(PrimaryButton(title: t("copyClose"), target: self, action: #selector(copyTextAndClose)))
            add(buttons)
        case .codes(let codes):
            for (i, code) in codes.enumerated() {
                payloads.append(code.payload)
                let value = NSTextField(wrappingLabelWithString: code.payload)
                value.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
                value.isSelectable = true; value.maximumNumberOfLines = 4
                value.lineBreakMode = .byCharWrapping
                add(value)
                let buttons = NSStackView(); buttons.spacing = 8
                let copy = FlatButton(title: t("copy"), target: self, action: #selector(copyCode(_:))); copy.tag = i
                buttons.addArrangedSubview(copy)
                if Recognition.webURL(code.payload) != nil {
                    let open = PrimaryButton(title: t("openLink"), target: self, action: #selector(openCode(_:))); open.tag = i
                    open.image = NSImage(systemSymbolName: "arrow.up.right.square", accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: 12, weight: .semibold))
                    buttons.addArrangedSubview(open)
                }
                add(buttons)
            }
        }
        layoutPanel()
    }

    private func add(_ view: NSView) {
        stack.addArrangedSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: width - 28).isActive = true
    }

    private func layoutPanel() {
        stack.translatesAutoresizingMaskIntoConstraints = true
        stack.frame = NSRect(x: 0, y: 0, width: width, height: 10)
        stack.layoutSubtreeIfNeeded()
        let height = stack.fittingSize.height
        frame.size = NSSize(width: width, height: height)
        background.frame = bounds
        stack.frame = background.bounds
    }

    /// Arrow over the panel, I-beam over editable or selectable text.
    func cursor(at point: NSPoint) -> NSCursor {
        if let scroll = textView?.enclosingScrollView, scroll.convert(scroll.bounds, to: self).contains(point) { return .iBeam }
        // hitTest takes a point in the superview's coordinates.
        if let parent = superview, let hit = hitTest(convert(point, to: parent)) as? NSTextField, hit.isSelectable { return .iBeam }
        return .arrow
    }

    func focusText() { if let textView { window?.makeFirstResponder(textView) } }

    @objc private func closePressed() { onClose() }
    @objc private func joinLines() {
        guard let textView else { return }
        let joined = textView.string.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
        textView.string = joined
    }
    /// Brief "Copied" on the button itself, since the overlay hides system alerts.
    private func flash(_ sender: NSButton) {
        let original = sender.attributedTitle
        sender.attributedTitle = NSAttributedString(string: t("copied"), attributes: original.attributes(at: 0, effectiveRange: nil))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { sender.attributedTitle = original }
    }
    @objc private func copyText(_ sender: NSButton) { onCopy(textView?.string ?? "", false); flash(sender) }
    @objc private func copyTextAndClose() { onCopy(textView?.string ?? "", true) }
    @objc private func copyCode(_ sender: NSButton) { if payloads.indices.contains(sender.tag) { onCopy(payloads[sender.tag], false); flash(sender) } }
    @objc private func openCode(_ sender: NSButton) {
        guard payloads.indices.contains(sender.tag), let url = Recognition.webURL(payloads[sender.tag]) else { return }
        onOpen(url)
    }
}
