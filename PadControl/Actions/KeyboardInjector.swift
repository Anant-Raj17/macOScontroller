import CoreGraphics
import Foundation

final class KeyboardInjector {
    private let source = CGEventSource(stateID: .hidSystemState)

    /// Left Control virtual key — used when posting real modifier down/up around arrows.
    private static let leftControlKey: CGKeyCode = 0x3B

    func tap(keyCode: CGKeyCode, flags: CGEventFlags) {
        post(keyCode: keyCode, flags: flags, keyDown: true)
        post(keyCode: keyCode, flags: flags, keyDown: false)
    }

    /// Mission Control “Move left/right a space” only recognizes Control+Arrow when the
    /// arrow also carries `.maskSecondaryFn`, matching a physical keyboard event.
    func tapSpaceSwitch(directionKeyCode: CGKeyCode) {
        let arrowFlags: CGEventFlags = [.maskControl, .maskSecondaryFn]
        post(keyCode: Self.leftControlKey, flags: .maskControl, keyDown: true)
        post(keyCode: directionKeyCode, flags: arrowFlags, keyDown: true)
        post(keyCode: directionKeyCode, flags: arrowFlags, keyDown: false)
        post(keyCode: Self.leftControlKey, flags: [], keyDown: false)
    }

    private func post(keyCode: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) else { return }
        event.flags = flags
        event.timestamp = CGEventTimestamp(ProcessInfo.processInfo.systemUptime * 1_000_000_000)
        event.post(tap: .cghidEventTap)
    }
}
