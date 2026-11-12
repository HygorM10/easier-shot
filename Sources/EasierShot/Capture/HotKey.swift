import AppKit
import Carbon.HIToolbox

/// System-wide hotkey using the Carbon hotkey API (no Accessibility permission needed).
@MainActor
final class HotKey {
    static let keyCode2 = UInt32(kVK_ANSI_2)
    static let commandShift = UInt32(cmdKey | shiftKey)

    private static var action: (() -> Void)?
    private static var handlerRef: EventHandlerRef?

    private let keyCode: UInt32
    private let modifiers: UInt32
    private var hotKeyRef: EventHotKeyRef?

    var isRegistered: Bool { hotKeyRef != nil }

    init(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        HotKey.action = action
    }

    /// Registers the hotkey. Returns false when the system refuses it (e.g. the combination is taken).
    @discardableResult
    func register() -> Bool {
        if isRegistered { return true }
        guard HotKey.installHandlerIfNeeded() else { return false }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4553_4854), id: 1) // "ESHT"
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else {
            NSLog("EasierShot: could not register the global shortcut (OSStatus %d)", Int(status))
            return false
        }
        hotKeyRef = ref
        return true
    }

    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        hotKeyRef = nil
    }

    private static func installHandlerIfNeeded() -> Bool {
        if handlerRef != nil { return true }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            Task { @MainActor in HotKey.action?() }
            return noErr
        }, 1, &spec, nil, &handlerRef)
        return status == noErr
    }
}
