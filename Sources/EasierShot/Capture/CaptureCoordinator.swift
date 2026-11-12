import AppKit
import SwiftUI

enum EditorAction {
    case copy, save, pin, cancel
}

/// Drives a capture session: grabs the screens, shows the editor overlays and runs the final action.
@MainActor
final class CaptureCoordinator {
    static let shared = CaptureCoordinator()

    private var windows: [OverlayWindow] = []
    private var models: [EditorModel] = []
    private var keyMonitor: Any?
    private var scrollMonitor: Any?
    private var scrollAccumulator: CGFloat = 0
    private var pins: [PinWindow] = []
    private var isCapturing = false
    private var previousApp: NSRunningApplication?

    // MARK: - Session lifecycle

    func startCapture() {
        guard !isCapturing else { return }
        guard ScreenCapturer.hasPermission else {
            ScreenCapturer.requestPermission()
            return
        }

        isCapturing = true
        let frontmost = NSWorkspace.shared.frontmostApplication
        previousApp = frontmost?.processIdentifier == ProcessInfo.processInfo.processIdentifier ? nil : frontmost
        Task {
            do {
                // Give the menu bar menu time to disappear before the shot.
                try await Task.sleep(nanoseconds: 200_000_000)
                let shots = try await ScreenCapturer.captureAll()
                guard !shots.isEmpty else { throw CocoaError(.featureUnsupported) }
                present(shots)
            } catch {
                isCapturing = false
                showError(AppSettings.shared.t(.captureFailed), error)
            }
        }
    }

    private func present(_ shots: [CapturedScreen]) {
        let mouse = NSEvent.mouseLocation
        // The screen under the pointer goes last so that its window ends up key.
        let ordered = shots.sorted { a, b in !a.screen.frame.contains(mouse) && b.screen.frame.contains(mouse) }

        AppActivation.bringToFront()
        for shot in ordered {
            let model = EditorModel(image: shot.image, screen: shot.screen)
            model.coordinator = self
            let window = OverlayWindow(screen: shot.screen)
            window.contentView = FirstMouseHostingView(rootView: EditorView(model: model))
            window.makeKeyAndOrderFront(nil)
            models.append(model)
            windows.append(window)
        }
        installMonitors()
    }

    private func closeSession() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let scrollMonitor { NSEvent.removeMonitor(scrollMonitor) }
        keyMonitor = nil
        scrollMonitor = nil
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        models.removeAll()
        isCapturing = false
        NSCursor.arrow.set()
    }

    /// Gives keyboard focus back to the app the user was in before the capture.
    private func restoreFocus() {
        previousApp?.activate(options: [])
        previousApp = nil
    }

    // MARK: - Actions

    func handle(_ action: EditorAction, from model: EditorModel) {
        if action == .cancel {
            closeSession()
            restoreFocus()
            return
        }

        guard let output = model.renderOutput() else {
            closeSession()
            restoreFocus()
            return
        }
        let screenFrame = model.screen.frame
        closeSession()

        switch action {
        case .copy:
            ImageExporter.copyToClipboard(output.image, pointSize: output.rect.size)
        case .save:
            ImageExporter.saveWithPanel(output.image, pointSize: output.rect.size)
        case .pin:
            let frame = CGRect(x: screenFrame.minX + output.rect.minX,
                               y: screenFrame.maxY - output.rect.maxY,
                               width: output.rect.width,
                               height: output.rect.height)
            pins.removeAll { !$0.isVisible }
            let pin = PinWindow(image: output.image, frame: frame)
            pin.orderFrontRegardless()
            pins.append(pin)
        case .cancel:
            break
        }
        restoreFocus()
    }

    // MARK: - Keyboard and scroll wheel

    private var activeModel: EditorModel? {
        for (index, window) in windows.enumerated() where window.isKeyWindow {
            return models[index]
        }
        return models.first { $0.selection != nil } ?? models.last
    }

    private func installMonitors() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isCapturing, let model = self.activeModel else { return event }
            return self.handleKey(event, model: model)
        }
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, self.isCapturing, let model = self.activeModel else { return event }
            self.handleScroll(event, model: model)
            return nil
        }
    }

    private func handleKey(_ event: NSEvent, model: EditorModel) -> NSEvent? {
        let escape: UInt16 = 53, returnKey: UInt16 = 36, enterKey: UInt16 = 76

        // While typing text, only Esc is intercepted; everything else goes to the field.
        if model.textDraft != nil {
            if event.keyCode == escape {
                model.textDraft = nil
                return nil
            }
            return event
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let command = flags.contains(.command)
        let shift = flags.contains(.shift)
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""

        if event.keyCode == escape {
            handle(.cancel, from: model)
        } else if event.keyCode == returnKey || event.keyCode == enterKey {
            handle(.copy, from: model)
        } else if command && key == "c" {
            handle(.copy, from: model)
        } else if command && key == "s" {
            handle(.save, from: model)
        } else if command && key == "z" {
            if shift { model.redo() } else { model.undo() }
        }
        return nil
    }

    private func handleScroll(_ event: NSEvent, model: EditorModel) {
        let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.scrollingDeltaY * 10
        scrollAccumulator += delta
        while scrollAccumulator >= 10 {
            model.changeLineWidth(by: 1)
            scrollAccumulator -= 10
        }
        while scrollAccumulator <= -10 {
            model.changeLineWidth(by: -1)
            scrollAccumulator += 10
        }
    }

    // MARK: - Alerts

    private func showError(_ title: String, _ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        AppActivation.bringToFront()
        alert.runModal()
    }
}
