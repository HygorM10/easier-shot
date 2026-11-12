import SwiftUI
import AppKit

@main
@MainActor
struct EasierShotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var settings = AppSettings.shared

    var body: some Scene {
        MenuBarExtra {
            Button(settings.t(.capture)) {
                CaptureCoordinator.shared.startCapture()
            }
            .keyboardShortcut("2", modifiers: [.command, .shift])

            Divider()

            Button(settings.t(.settings)) {
                SettingsWindowController.shared.show()
            }

            Divider()

            Button(settings.t(.quit)) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(nsImage: AppIcon.menuBar)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppSettings.shared.applyTheme()
        Installer.runAtLaunch()
        // Global shortcut: Cmd + Shift + 2
        let hotKey = HotKey(keyCode: HotKey.keyCode2, modifiers: HotKey.commandShift) {
            CaptureCoordinator.shared.startCapture()
        }
        self.hotKey = hotKey
        if hotKey.register() {
            AppSettings.shared.hotKeyAvailable = true
        } else {
            // A previous instance may still be quitting (e.g. right after installing): try once more.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                AppSettings.shared.hotKeyAvailable = hotKey.register()
            }
        }
    }
}
