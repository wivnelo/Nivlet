import AppKit

/// UI strings. Defaults are Simplified Chinese; Lua sends the active language's translations.
var strings: [String: String] = [
    "rect": "矩形", "arrow": "箭头", "pen": "画笔", "text": "文字", "mosaic": "马赛克",
    "undo": "撤销", "redo": "重做", "save": "保存", "cancel": "取消", "copy": "复制",
    "pixelate": "像素化", "blackout": "涂黑", "copyColorHint": "C 复制颜色",
]
func t(_ key: String) -> String { strings[key] ?? key }

enum ToolbarAction { case tool(Tool), undo, redo, save, cancel, copy }

/// A small button that shows an SF Symbol and a pressed state, sized for a 30 pt toolbar.
final class ToolButton: NSButton {
    var selectedState = false { didSet { needsDisplay = true; updateLayer() } }
    override var wantsUpdateLayer: Bool { true }

    convenience init(symbol: String, tooltip: String, target: AnyObject, action: Selector) {
        self.init(frame: NSRect(x: 0, y: 0, width: 32, height: 30))
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)?.withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
        imagePosition = .imageOnly
        isBordered = false
        toolTip = tooltip
        setAccessibilityLabel(tooltip)
        self.target = target; self.action = action
        wantsLayer = true
        layer?.cornerRadius = 7
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 32).isActive = true
        heightAnchor.constraint(equalToConstant: 30).isActive = true
    }

    override func updateLayer() {
        layer?.backgroundColor = selectedState ? accentColor.withAlphaComponent(0.16).cgColor : NSColor.clear.cgColor
        contentTintColor = selectedState ? accentColor : .labelColor
    }
}

/// Nivlet's own palette (settings page tokens) so the overlay matches the app instead of the
/// near-black system popover material.
func dynamicColor(light: NSColor, dark: NSColor) -> NSColor {
    NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light }
}
let barBackground = dynamicColor(light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.97), dark: NSColor(srgbRed: 0.17, green: 0.17, blue: 0.18, alpha: 0.97))
let barBorder = dynamicColor(light: NSColor(srgbRed: 0.87, green: 0.87, blue: 0.89, alpha: 1), dark: NSColor(srgbRed: 0.24, green: 0.24, blue: 0.25, alpha: 1))
let accentColor = dynamicColor(light: NSColor(srgbRed: 0, green: 0.48, blue: 1, alpha: 1), dark: NSColor(srgbRed: 0.04, green: 0.52, blue: 1, alpha: 1))

/// Floating bar background used by both bars.
final class BarBackground: NSView {
    override var wantsUpdateLayer: Bool { true }
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        layer?.shadowOpacity = 0.22; layer?.shadowRadius = 10; layer?.shadowOffset = CGSize(width: 0, height: -3)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func updateLayer() {
        layer?.backgroundColor = barBackground.cgColor
        layer?.borderColor = barBorder.cgColor
    }
}
func makeHUD() -> NSView { BarBackground() }

/// Flat accent button for the primary action, matching the settings page's blue buttons.
final class PrimaryButton: NSButton {
    override var wantsUpdateLayer: Bool { true }
    convenience init(title: String, target: AnyObject, action: Selector) {
        self.init(frame: .zero)
        self.title = title
        isBordered = false
        image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: 12, weight: .semibold))
        imagePosition = .imageLeading
        imageHugsTitle = true
        self.target = target; self.action = action
        wantsLayer = true
        layer?.cornerRadius = 7
        contentTintColor = .white
        attributedTitle = NSAttributedString(string: " " + title, attributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 12.5, weight: .semibold)])
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 28).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: 68).isActive = true
    }
    override func updateLayer() { layer?.backgroundColor = accentColor.cgColor }
}

@MainActor
final class Toolbar: NSView {
    var onAction: (ToolbarAction) -> Void = { _ in }
    private var toolButtons: [Tool: ToolButton] = [:]
    private let hud = makeHUD()

    init() {
        super.init(frame: .zero)
        addSubview(hud)
        let stack = NSStackView()
        stack.orientation = .horizontal; stack.spacing = 2; stack.edgeInsets = NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        let symbols: [(Tool, String, String)] = [(.rect, "rectangle", "R"), (.arrow, "arrow.up.right", "A"), (.pen, "scribble", "B"), (.text, "textformat", "T"), (.mosaic, "checkerboard.rectangle", "M")]
        for (tool, symbol, key) in symbols {
            let b = ToolButton(symbol: symbol, tooltip: "\(t(tool.rawValue))  \(key)", target: self, action: #selector(toolPressed(_:)))
            b.identifier = NSUserInterfaceItemIdentifier(tool.rawValue)
            toolButtons[tool] = b; stack.addArrangedSubview(b)
        }
        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(ToolButton(symbol: "arrow.uturn.backward", tooltip: "\(t("undo"))  ⌘Z", target: self, action: #selector(undo)))
        stack.addArrangedSubview(ToolButton(symbol: "arrow.uturn.forward", tooltip: "\(t("redo"))  ⇧⌘Z", target: self, action: #selector(redo)))
        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(ToolButton(symbol: "square.and.arrow.down", tooltip: "\(t("save"))  ⌘S", target: self, action: #selector(save)))
        stack.addArrangedSubview(ToolButton(symbol: "xmark", tooltip: "\(t("cancel"))  Esc", target: self, action: #selector(cancel)))
        let copy = PrimaryButton(title: t("copy"), target: self, action: #selector(copyPressed))
        copy.toolTip = "\(t("copy"))  ↩"
        stack.addArrangedSubview(copy)
        hud.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: hud.leadingAnchor), stack.trailingAnchor.constraint(equalTo: hud.trailingAnchor),
                                     stack.topAnchor.constraint(equalTo: hud.topAnchor), stack.bottomAnchor.constraint(equalTo: hud.bottomAnchor)])
        let size = stack.fittingSize
        frame.size = size; hud.frame = NSRect(origin: .zero, size: size)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func separator() -> NSView {
        let v = NSBox(); v.boxType = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: 9).isActive = true
        v.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return v
    }

    func select(_ tool: Tool?) { toolButtons.forEach { $0.value.selectedState = $0.key == tool } }

    @objc private func toolPressed(_ sender: NSButton) { if let id = sender.identifier?.rawValue, let tool = Tool(rawValue: id) { onAction(.tool(tool)) } }
    @objc private func undo() { onAction(.undo) }
    @objc private func redo() { onAction(.redo) }
    @objc private func save() { onAction(.save) }
    @objc private func cancel() { onAction(.cancel) }
    @objc private func copyPressed() { onAction(.copy) }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Second bar: colour, stroke or text size, and mosaic mode for the active tool.
@MainActor
final class PropertyBar: NSView {
    var onChange: () -> Void = {}
    var colorIndex = 0, sizeIndex = 1
    var mosaicMode: MosaicMode = .pixelate
    private let hud = makeHUD()
    private let stack = NSStackView()

    init() {
        super.init(frame: .zero)
        addSubview(hud)
        stack.orientation = .horizontal; stack.spacing = 8; stack.edgeInsets = NSEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        hud.addSubview(stack)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func configure(for tool: Tool) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if tool == .mosaic {
            let seg = NSSegmentedControl(labels: [t("pixelate"), t("blackout")], trackingMode: .selectOne, target: self, action: #selector(modeChanged(_:)))
            seg.selectedSegment = mosaicMode == .pixelate ? 0 : 1; seg.controlSize = .small
            stack.addArrangedSubview(seg)
            if mosaicMode == .pixelate { stack.addArrangedSubview(sizeDots()) }
        } else {
            for (i, color) in palette.enumerated() {
                let dot = Dot(color: color, diameter: 18, selected: i == colorIndex)
                dot.onClick = { [weak self] in self?.colorIndex = i; self?.configure(for: tool); self?.onChange() }
                dot.toolTip = "\(i + 1)"
                stack.addArrangedSubview(dot)
            }
            stack.addArrangedSubview(Spacer())
            stack.addArrangedSubview(sizeDots())
        }
        layoutHUD()
        currentTool = tool
    }
    private var currentTool: Tool = .rect

    private func sizeDots() -> NSView {
        let row = NSStackView(); row.spacing = 7; row.alignment = .centerY
        for (i, d) in [CGFloat(6), 10, 15].enumerated() {
            let dot = Dot(color: .labelColor, diameter: d, selected: i == sizeIndex, faded: i != sizeIndex)
            dot.onClick = { [weak self] in guard let self else { return }; self.sizeIndex = i; self.configure(for: self.currentTool); self.onChange() }
            row.addArrangedSubview(dot)
        }
        return row
    }

    @objc private func modeChanged(_ sender: NSSegmentedControl) {
        mosaicMode = sender.selectedSegment == 0 ? .pixelate : .blackout
        configure(for: .mosaic); onChange()
    }

    private func layoutHUD() {
        stack.layoutSubtreeIfNeeded()
        let size = stack.fittingSize
        frame.size = size; hud.frame = NSRect(origin: .zero, size: size); stack.frame = hud.bounds
    }
}

final class Spacer: NSView {
    override var intrinsicContentSize: NSSize { NSSize(width: 4, height: 1) }
}

/// Round swatch used for colours and sizes.
final class Dot: NSView {
    var onClick: () -> Void = {}
    let color: NSColor, diameter: CGFloat, selected: Bool, faded: Bool
    init(color: NSColor, diameter: CGFloat, selected: Bool, faded: Bool = false) {
        self.color = color; self.diameter = diameter; self.selected = selected; self.faded = faded
        super.init(frame: NSRect(x: 0, y: 0, width: max(diameter, 18) + 4, height: 22))
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: max(diameter, 18) + 4).isActive = true
        heightAnchor.constraint(equalToConstant: 22).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ dirtyRect: NSRect) {
        let r = NSRect(x: (bounds.width - diameter) / 2, y: (bounds.height - diameter) / 2, width: diameter, height: diameter)
        (faded ? color.withAlphaComponent(0.4) : color).setFill()
        NSBezierPath(ovalIn: r).fill()
        if diameter >= 18 {
            // Thin outline keeps dark and light swatches visible on either bar colour.
            NSColor.separatorColor.setStroke()
            let edge = NSBezierPath(ovalIn: r.insetBy(dx: 0.5, dy: 0.5)); edge.lineWidth = 1; edge.stroke()
        }
        if selected && diameter >= 18 {
            NSColor.labelColor.setStroke()
            let ring = NSBezierPath(ovalIn: r.insetBy(dx: -2, dy: -2)); ring.lineWidth = 1.5; ring.stroke()
        }
    }
    override func mouseDown(with event: NSEvent) { onClick() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
