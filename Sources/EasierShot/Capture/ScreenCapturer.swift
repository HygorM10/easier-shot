import AppKit
import ScreenCaptureKit

struct CapturedScreen {
    let screen: NSScreen
    let image: CGImage
}

enum ScreenCapturer {
    static var hasPermission: Bool { CGPreflightScreenCaptureAccess() }

    static func requestPermission() { CGRequestScreenCaptureAccess() }

    /// The screen the user is working on: the one holding the window with keyboard focus.
    /// Falls back to the screen under the mouse pointer, then to the primary screen.
    @MainActor
    static var focusedScreen: NSScreen? {
        if let main = NSScreen.main { return main }
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.screens.first
    }

    /// Takes one still image of the given screen only.
    @MainActor
    static func capture(_ screen: NSScreen) async throws -> CapturedScreen {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let number = screen.deviceDescription[key] as? NSNumber,
              let display = content.displays.first(where: { $0.displayID == number.uint32Value })
        else { throw CocoaError(.featureUnsupported) }

        let scale = screen.backingScaleFactor
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = Int(screen.frame.width * scale)
        config.height = Int(screen.frame.height * scale)
        config.showsCursor = false
        config.captureResolution = .best

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        return CapturedScreen(screen: screen, image: image)
    }
}
