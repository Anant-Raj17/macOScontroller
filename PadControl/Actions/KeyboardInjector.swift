import CoreGraphics
import Foundation

final class KeyboardInjector {
    private let source = CGEventSource(stateID: .hidSystemState)
    private(set) var heldModifier: CGKeyCode?

    func tap(keyCode: CGKeyCode, flags: CGEventFlags) {
        post(keyCode: keyCode, flags: flags, keyDown: true)
        post(keyCode: keyCode, flags: flags, keyDown: false)
    }

    /// Hold a physical modifier key (e.g. Right Option for push-to-talk dictation).
    func modifierDown(_ keyCode: CGKeyCode) {
        let flags = KeyChord.flagMask(forModifierKeyCode: UInt16(keyCode))
        heldModifier = keyCode
        post(keyCode: keyCode, flags: flags, keyDown: true)
    }

    func modifierUp(_ keyCode: CGKeyCode) {
        post(keyCode: keyCode, flags: [], keyDown: false)
        if heldModifier == keyCode {
            heldModifier = nil
        }
    }

    func releaseHeldModifier() {
        guard let keyCode = heldModifier else { return }
        modifierUp(keyCode)
    }

    private func post(keyCode: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) else { return }
        event.flags = flags
        event.timestamp = CGEventTimestamp(ProcessInfo.processInfo.systemUptime * 1_000_000_000)
        event.post(tap: .cghidEventTap)
    }
}
