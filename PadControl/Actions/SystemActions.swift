import AppKit
import CoreGraphics

enum SystemActions {
    private static let keyboard = KeyboardInjector()

    static func missionControl() {
        let url = URL(fileURLWithPath: "/System/Applications/Mission Control.app")
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.open(url)
            return
        }
        keyboard.tap(keyCode: 126, flags: .maskControl)
    }

    static func appExpose() {
        keyboard.tap(keyCode: 125, flags: .maskControl)
    }

    static func showDesktop() {
        keyboard.tap(keyCode: 103, flags: [])
    }
}
