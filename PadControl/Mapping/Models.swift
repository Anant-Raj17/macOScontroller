import AppKit
import CoreGraphics
import Foundation

enum ControlInput: String, Codable, CaseIterable, Identifiable, Hashable {
    case buttonA
    case buttonB
    case buttonX
    case buttonY
    case leftShoulder
    case rightShoulder
    case leftTrigger
    case rightTrigger
    case leftThumbstickButton
    case rightThumbstickButton
    case dpadUp
    case dpadDown
    case dpadLeft
    case dpadRight
    case leftStick
    case rightStick
    case buttonMenu
    case buttonOptions
    case buttonHome

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .buttonA: return "A / Cross"
        case .buttonB: return "B / Circle"
        case .buttonX: return "X / Square"
        case .buttonY: return "Y / Triangle"
        case .leftShoulder: return "Left bumper"
        case .rightShoulder: return "Right bumper"
        case .leftTrigger: return "Left trigger"
        case .rightTrigger: return "Right trigger"
        case .leftThumbstickButton: return "Left stick click"
        case .rightThumbstickButton: return "Right stick click"
        case .dpadUp: return "D-pad up"
        case .dpadDown: return "D-pad down"
        case .dpadLeft: return "D-pad left"
        case .dpadRight: return "D-pad right"
        case .leftStick: return "Left stick"
        case .rightStick: return "Right stick"
        case .buttonMenu: return "Menu"
        case .buttonOptions: return "Options"
        case .buttonHome: return "Home"
        }
    }

    var isAnalogStick: Bool {
        self == .leftStick || self == .rightStick
    }

    var symbolName: String {
        switch self {
        case .buttonA, .buttonB, .buttonX, .buttonY:
            return "circle.grid.2x2"
        case .leftShoulder, .rightShoulder:
            return "button.horizontal"
        case .leftTrigger, .rightTrigger:
            return "r.joystick.tilt.down"
        case .leftThumbstickButton, .rightThumbstickButton, .leftStick, .rightStick:
            return "l.joystick"
        case .dpadUp, .dpadDown, .dpadLeft, .dpadRight:
            return "dpad"
        case .buttonMenu, .buttonOptions, .buttonHome:
            return "line.3.horizontal"
        }
    }
}

enum Action: Codable, Equatable, Hashable {
    case unbound
    case mouseMove
    case mouseClickLeft
    case mouseClickRight
    case mouseClickMiddle
    case mouseScroll
    case keyCombo(keyCode: UInt16, flags: UInt64)
    case missionControl
    case appExpose
    case showDesktop
    case switchSpaceLeft
    case switchSpaceRight
    case focusTextField

    var displayName: String {
        switch self {
        case .unbound: return "Unbound"
        case .mouseMove: return "Move pointer"
        case .mouseClickLeft: return "Left click"
        case .mouseClickRight: return "Right click"
        case .mouseClickMiddle: return "Middle click"
        case .mouseScroll: return "Scroll"
        case .keyCombo(let keyCode, let flags):
            return KeyChord.format(keyCode: keyCode, flags: CGEventFlags(rawValue: flags))
        case .missionControl: return "Mission Control"
        case .appExpose: return "App Exposé"
        case .showDesktop: return "Show Desktop"
        case .switchSpaceLeft: return "Switch Space left"
        case .switchSpaceRight: return "Switch Space right"
        case .focusTextField: return "Focus text field"
        }
    }

    var isContinuousStickAction: Bool {
        self == .mouseMove || self == .mouseScroll
    }
}

struct AnalogState: Equatable {
    var leftStick = SIMD2<Float>.zero
    var rightStick = SIMD2<Float>.zero

    static let zero = AnalogState()

    func stick(_ input: ControlInput) -> SIMD2<Float> {
        switch input {
        case .leftStick: return leftStick
        case .rightStick: return rightStick
        default: return .zero
        }
    }
}

struct Profile: Codable, Equatable {
    var bindings: [ControlInput: Action]
    var deadzone: Double
    var mouseSpeed: Double
    var scrollSpeed: Double

    static let `default` = Profile(
        bindings: [
            .dpadUp: .missionControl,
            .dpadLeft: .switchSpaceLeft,
            .dpadRight: .switchSpaceRight,
            .rightStick: .mouseMove,
            .leftTrigger: .mouseClickLeft,
            .rightTrigger: .mouseClickRight,
            .buttonA: .focusTextField
        ],
        deadzone: 0.14,
        mouseSpeed: 18,
        scrollSpeed: 6
    )

    func action(for input: ControlInput) -> Action {
        bindings[input] ?? .unbound
    }
}

enum KeyChord {
    /// Virtual key codes for physical modifier keys (left/right distinguished).
    static let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]

    static func isModifierKeyCode(_ keyCode: UInt16) -> Bool {
        modifierKeyCodes.contains(keyCode)
    }

    /// A lone modifier (e.g. Right Option) — not a chord with another key.
    static func isModifierOnly(keyCode: UInt16, flags: CGEventFlags) -> Bool {
        isModifierKeyCode(keyCode) && flags.isEmpty
    }

    static func format(keyCode: UInt16, flags: CGEventFlags) -> String {
        if isModifierOnly(keyCode: keyCode, flags: flags) {
            return modifierName(keyCode)
        }
        var parts: [String] = []
        if flags.contains(.maskControl) { parts.append("⌃") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        if flags.contains(.maskCommand) { parts.append("⌘") }
        parts.append(keyName(keyCode))
        return parts.joined()
    }

    static func flags(from cocoa: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []
        if cocoa.contains(.control) { flags.insert(.maskControl) }
        if cocoa.contains(.option) { flags.insert(.maskAlternate) }
        if cocoa.contains(.shift) { flags.insert(.maskShift) }
        if cocoa.contains(.command) { flags.insert(.maskCommand) }
        return flags
    }

    static func flagMask(forModifierKeyCode keyCode: UInt16) -> CGEventFlags {
        switch keyCode {
        case 54, 55: return .maskCommand
        case 56, 60: return .maskShift
        case 57: return .maskAlphaShift
        case 58, 61: return .maskAlternate
        case 59, 62: return .maskControl
        case 63: return .maskSecondaryFn
        default: return []
        }
    }

    /// Whether `flagsChanged` reflects this modifier transitioning to down.
    static func modifierIsDown(keyCode: UInt16, flags: NSEvent.ModifierFlags) -> Bool {
        let device = flags.intersection(.deviceIndependentFlagsMask)
        switch keyCode {
        case 54, 55: return device.contains(.command)
        case 56, 60: return device.contains(.shift)
        case 57: return device.contains(.capsLock)
        case 58, 61: return device.contains(.option)
        case 59, 62: return device.contains(.control)
        case 63: return device.contains(.function)
        default: return false
        }
    }

    static func modifierName(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 54: return "Right ⌘"
        case 55: return "Left ⌘"
        case 56: return "Left ⇧"
        case 57: return "Caps Lock"
        case 58: return "Left ⌥"
        case 59: return "Left ⌃"
        case 60: return "Right ⇧"
        case 61: return "Right ⌥"
        case 62: return "Right ⌃"
        case 63: return "Fn"
        default: return "Key \(keyCode)"
        }
    }

    static func keyName(_ keyCode: UInt16) -> String {
        if isModifierKeyCode(keyCode) {
            return modifierName(keyCode)
        }
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "Delete"
        case 53: return "Esc"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 109: return "F10"
        case 111: return "F12"
        case 118: return "F4"
        case 120: return "F2"
        case 122: return "F1"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "Key \(keyCode)"
        }
    }
}
