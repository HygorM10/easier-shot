import SwiftUI
import AppKit

@MainActor
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let theme = Theme.current(scheme)

        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                AppMarkView(size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("EasierShot")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(theme.text)
                    Text("v1.0.1")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.secondaryText)
                }
            }

            section(settings.t(.appearance), theme: theme) {
                Picker("", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { item in
                        Text(settings.t(item.titleKey)).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            section(settings.t(.language), theme: theme) {
                Picker("", selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            section(settings.t(.general), theme: theme) {
                Toggle(settings.t(.launchAtLogin), isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.setLaunchAtLogin($0) }
                ))
                .font(.system(size: 12))
            }

            section(settings.t(.shortcuts), theme: theme) {
                VStack(spacing: 6) {
                    shortcutRow(settings.t(.shortcutCapture), "⇧⌘2", theme)
                    shortcutRow(settings.t(.shortcutCopy), "⌘C / Enter", theme)
                    shortcutRow(settings.t(.shortcutSave), "⌘S", theme)
                    shortcutRow(settings.t(.shortcutUndo), "⌘Z / ⇧⌘Z", theme)
                    shortcutRow(settings.t(.shortcutThickness), settings.t(.scrollWheel), theme)
                    shortcutRow(settings.t(.shortcutCancel), "Esc", theme)
                    if !settings.hotKeyAvailable {
                        Label(settings.t(.hotKeyUnavailable), systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text(settings.t(.offlineNote))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.system(size: 11))
            .foregroundStyle(theme.secondaryText)
        }
        .padding(22)
        .frame(width: 430)
        .fixedSize(horizontal: false, vertical: true)
        .background(theme.background)
        .tint(theme.primary)
        .onChange(of: settings.language) { _, _ in
            SettingsWindowController.shared.updateTitle()
        }
    }

    private func section<Content: View>(_ title: String, theme: Theme,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(theme.secondaryText)
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
        }
    }

    private func shortcutRow(_ title: String, _ keys: String, _ theme: Theme) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(theme.text)
            Spacer()
            Text(keys)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.onPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(theme.primary))
        }
    }
}

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let controller = NSHostingController(rootView: SettingsView())
            let win = NSWindow(contentViewController: controller)
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.isReleasedWhenClosed = false
            win.center()
            window = win
        }
        updateTitle()
        AppActivation.bringToFront()
        window?.makeKeyAndOrderFront(nil)
    }

    func updateTitle() {
        let title = AppSettings.shared.t(.settings).replacingOccurrences(of: "…", with: "")
        window?.title = "EasierShot — \(title)"
    }
}
