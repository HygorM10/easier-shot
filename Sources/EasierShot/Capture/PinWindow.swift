import AppKit

/// Floating, always-on-top window that keeps a screenshot pinned on screen.
/// Drag to move, double-click to close, right-click for more options.
final class PinWindow: NSPanel {
    init(image: CGImage, frame: CGRect) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = PinView(image: image, size: frame.size)
    }

    override var canBecomeKey: Bool { true }
}

final class PinView: NSView {
    private let image: CGImage
    private let pointSize: CGSize

    init(image: CGImage, size: CGSize) {
        self.image = image
        self.pointSize = size
        super.init(frame: CGRect(origin: .zero, size: size))
        wantsLayer = true
        layer?.contents = image
        layer?.contentsGravity = .resize
        layer?.borderWidth = 2
        layer?.borderColor = Palette.amberNS.cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Built on demand so the titles always follow the current language.
    override func menu(for event: NSEvent) -> NSMenu? {
        let settings = AppSettings.shared
        let menu = NSMenu()
        for (title, selector) in [
            (settings.t(.copyShort), #selector(copyImage)),
            (settings.t(.saveShort), #selector(saveImage)),
            (settings.t(.closeShort), #selector(closePin)),
        ] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        return menu
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount >= 2 {
            window?.close()
        } else {
            window?.performDrag(with: event)
        }
    }

    @objc private func copyImage() {
        ImageExporter.copyToClipboard(image, pointSize: pointSize)
    }

    @objc private func saveImage() {
        ImageExporter.saveWithPanel(image, pointSize: pointSize)
    }

    @objc private func closePin() {
        window?.close()
    }
}
