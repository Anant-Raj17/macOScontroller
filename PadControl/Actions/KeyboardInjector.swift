import CoreGraphics
import Foundation

final class KeyboardInjector {
    private let source = CGEventSource(stateID: .hidSystemState)

    func tap(keyCode: CGKeyCode, flags: CGEventFlags) {
        post(keyCode: keyCode, flags: flags, keyDown: true)
        post(keyCode: keyCode, flags: flags, keyDown: false)
    }

    private func post(keyCode: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) else { return }
        event.flags = flags
        event.timestamp = CGEventTimestamp(ProcessInfo.processInfo.systemUptime * 1_000_000_000)
        event.post(tap: .cghidEventTap)
    }
}
