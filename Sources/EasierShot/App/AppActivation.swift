import AppKit

/// Single place where the app asks to come to the front.
@MainActor
enum AppActivation {
    static func bringToFront() {
        NSApp.activate()
    }
}
