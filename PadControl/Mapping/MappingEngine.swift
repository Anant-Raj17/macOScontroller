import AppKit
import Foundation
import QuartzCore

final class MappingEngine: NSObject {
    var enabled = true
    var profile = Profile.default
    var analogProvider: () -> AnalogState = { .zero }
    var isTrusted: () -> Bool = { false }

    private let mouse = MouseInjector()
    private let keyboard = KeyboardInjector()
    private let textFields = TextFieldFocuser()
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    func handleDigital(_ input: ControlInput, pressed: Bool) {
        guard enabled, isTrusted() else { return }
        let action = profile.action(for: input)
        switch action {
        case .unbound, .mouseMove, .mouseScroll:
            break
        case .mouseClickLeft:
            pressed ? mouse.down(.left) : mouse.up(.left)
        case .mouseClickRight:
            pressed ? mouse.down(.right) : mouse.up(.right)
        case .mouseClickMiddle:
            pressed ? mouse.down(.center) : mouse.up(.center)
        case .keyCombo(let keyCode, let flags):
            let eventFlags = CGEventFlags(rawValue: flags)
            if KeyChord.isModifierOnly(keyCode: keyCode, flags: eventFlags) {
                // Hold semantics for lone modifiers (dictation / push-to-talk).
                if pressed {
                    keyboard.modifierDown(CGKeyCode(keyCode))
                } else {
                    keyboard.modifierUp(CGKeyCode(keyCode))
                }
            } else if pressed {
                keyboard.tap(keyCode: CGKeyCode(keyCode), flags: eventFlags)
            }
        case .missionControl:
            if pressed { SystemActions.missionControl() }
        case .appExpose:
            if pressed { SystemActions.appExpose() }
        case .showDesktop:
            if pressed { SystemActions.showDesktop() }
        case .switchSpaceLeft:
            if pressed { SystemActions.switchSpaceLeft() }
        case .switchSpaceRight:
            if pressed { SystemActions.switchSpaceRight() }
        case .focusTextField:
            if pressed { textFields.focusNext() }
        }
    }

    func analogDidChange() {
        guard enabled, isTrusted() else {
            stopDisplayLink()
            return
        }
        if stickNeedsPolling(analogProvider()) {
            startDisplayLink()
        } else {
            stopDisplayLink()
        }
    }

    func stop() {
        stopDisplayLink()
        if mouse.heldButton == .left { mouse.up(.left) }
        if mouse.heldButton == .right { mouse.up(.right) }
        if mouse.heldButton == .center { mouse.up(.center) }
        keyboard.releaseHeldModifier()
    }

    private func stickNeedsPolling(_ analog: AnalogState) -> Bool {
        ControlInput.allCases.contains { input in
            guard input.isAnalogStick else { return false }
            let action = profile.action(for: input)
            guard action.isContinuousStickAction else { return false }
            return magnitude(analog.stick(input)) > profile.deadzone
        }
    }

    private func startDisplayLink() {
        guard displayLink == nil else { return }
        lastTimestamp = 0
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let link = screen.displayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: RunLoop.main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
    }

    @objc private func tick(_ link: CADisplayLink) {
        guard enabled, isTrusted() else { return }
        let now = link.timestamp
        let dt: CFTimeInterval
        if lastTimestamp == 0 {
            dt = link.duration > 0 ? link.duration : (1.0 / 60.0)
        } else {
            dt = max(1.0 / 240.0, min(now - lastTimestamp, 1.0 / 20.0))
        }
        lastTimestamp = now

        let analog = analogProvider()
        applyStick(.leftStick, vector: analog.leftStick, dt: dt)
        applyStick(.rightStick, vector: analog.rightStick, dt: dt)

        if !stickNeedsPolling(analog) {
            stopDisplayLink()
        }
    }

    private func applyStick(_ input: ControlInput, vector: SIMD2<Float>, dt: CFTimeInterval) {
        let mag = magnitude(vector)
        let deadzone = profile.deadzone
        guard mag > deadzone else { return }

        let scaled = min(1, (mag - deadzone) / (1 - deadzone))
        let accelerated = scaled * scaled
        let nx = Double(vector.x) / mag
        let ny = Double(vector.y) / mag
        let frameScale = dt * 60

        switch profile.action(for: input) {
        case .mouseMove:
            let pixels = accelerated * profile.mouseSpeed * frameScale
            mouse.move(dx: nx * pixels, dy: -ny * pixels)
        case .mouseScroll:
            let pixels = accelerated * profile.scrollSpeed * frameScale * 4
            mouse.scroll(dx: nx * pixels, dy: ny * pixels)
        default:
            break
        }
    }

    private func magnitude(_ vector: SIMD2<Float>) -> Double {
        hypot(Double(vector.x), Double(vector.y))
    }
}
