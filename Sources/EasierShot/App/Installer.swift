import AppKit

/// Handles the disk-image installer:
/// - launched from the disk image: offers to copy itself to Applications and reopens from there;
/// - launched from anywhere else: ejects the installer disk image if it is still mounted.
@MainActor
enum Installer {
    private static let appName = "EasierShot.app"
    private static let volumePrefix = "EasierShot"

    static func runAtLaunch() {
        let path = Bundle.main.bundlePath
        guard path.hasSuffix(".app") else { return } // e.g. `swift run`

        if path.hasPrefix("/Volumes/") || path.contains("/AppTranslocation/") {
            offerInstall(from: path)
        } else {
            ejectInstallerVolumes(attemptsLeft: 5)
        }
    }

    // MARK: - Install

    private static func offerInstall(from source: String) {
        let settings = AppSettings.shared
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = settings.t(.installTitle)
        alert.informativeText = settings.t(.installMessage)
        alert.addButton(withTitle: settings.t(.install))
        alert.addButton(withTitle: settings.t(.notNow))
        AppActivation.bringToFront()
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let fileManager = FileManager.default
        let applications = URL(fileURLWithPath: "/Applications")
        let destination = applications.appendingPathComponent(appName)
        let staging = applications.appendingPathComponent(".EasierShot-\(UUID().uuidString).app")
        do {
            // Copy next to the destination first: an existing install is only touched once
            // the new copy is complete.
            try fileManager.copyItem(at: URL(fileURLWithPath: source), to: staging)
            quitInstalledInstances(at: destination)
            if fileManager.fileExists(atPath: destination.path) {
                _ = try fileManager.replaceItemAt(destination, withItemAt: staging)
            } else {
                try fileManager.moveItem(at: staging, to: destination)
            }
        } catch {
            try? fileManager.removeItem(at: staging)
            let failure = NSAlert()
            failure.alertStyle = .warning
            failure.messageText = settings.t(.installFailed)
            failure.informativeText = error.localizedDescription
            failure.runModal()
            return
        }

        // Open the installed copy (it ejects the disk image) and quit this one.
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: destination, configuration: configuration) { _, _ in
            Task { @MainActor in NSApp.terminate(nil) }
        }
    }

    /// Asks an already-installed copy that is running to quit before it gets replaced.
    private static func quitInstalledInstances(at destination: URL) {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        where app.processIdentifier != ownPID
            && app.bundleURL?.standardizedFileURL.path == destination.standardizedFileURL.path {
            app.terminate()
        }
    }

    // MARK: - Eject

    private static func ejectInstallerVolumes(attemptsLeft: Int) {
        let fileManager = FileManager.default
        let volumes = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: nil,
                                                    options: [.skipHiddenVolumes]) ?? []
        let installers = volumes.filter { volume in
            volume.path.hasPrefix("/Volumes/")
                && volume.lastPathComponent.hasPrefix(volumePrefix)
                && fileManager.fileExists(atPath: volume.appendingPathComponent(appName).path)
        }
        guard !installers.isEmpty else { return }

        var failed = false
        for volume in installers {
            do {
                try NSWorkspace.shared.unmountAndEjectDevice(at: volume)
            } catch {
                failed = true
            }
        }

        // The volume can still be busy for a moment (Finder window, previous instance quitting).
        if failed && attemptsLeft > 1 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                ejectInstallerVolumes(attemptsLeft: attemptsLeft - 1)
            }
        }
    }
}
