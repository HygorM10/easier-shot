import AppKit
import UniformTypeIdentifiers

@MainActor
enum ImageExporter {
    static func copyToClipboard(_ image: CGImage, pointSize: CGSize) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([NSImage(cgImage: image, size: pointSize)])
    }

    static func saveWithPanel(_ image: CGImage, pointSize: CGSize) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "EasierShot-\(formatter.string(from: Date())).png"

        AppActivation.bringToFront()
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let rep = NSBitmapImageRep(cgImage: image)
        rep.size = pointSize
        do {
            guard let data = rep.representation(using: .png, properties: [:]) else {
                throw CocoaError(.fileWriteUnknown)
            }
            try data.write(to: url, options: .atomic)
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = AppSettings.shared.t(.saveFailed)
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}
