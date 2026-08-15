import SwiftUI

struct ActionPicker: View {
    @EnvironmentObject private var model: AppModel
    let input: ControlInput
    @State private var captureShortcut = false

    private var current: Action {
        model.store.profile.action(for: input)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(input.displayName)
                .font(.headline)
            Text("Choose what this control does globally.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Action", selection: actionKindBinding) {
                ForEach(kindOptions, id: \.self) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            if captureShortcut || isKeyCombo {
                ShortcutRecorder(
                    keyCode: keyComboValues.keyCode,
                    flags: keyComboValues.flags
                ) { keyCode, flags in
                    model.store.setAction(.keyCombo(keyCode: keyCode, flags: flags), for: input)
                    captureShortcut = false
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onChange(of: input) { _, _ in
            captureShortcut = false
        }
    }

    private var isKeyCombo: Bool {
        if case .keyCombo = current { return true }
        return false
    }

    private var keyComboValues: (keyCode: UInt16, flags: UInt64) {
        if case .keyCombo(let keyCode, let flags) = current {
            return (keyCode, flags)
        }
        return (0, 0)
    }

    private var kindOptions: [ActionKind] {
        if input.isAnalogStick {
            return [.unbound, .mouseMove, .mouseScroll]
        }
        return [
            .unbound,
            .leftClick,
            .rightClick,
            .middleClick,
            .shortcut,
            .missionControl,
            .appExpose,
            .showDesktop,
            .switchSpaceLeft,
            .switchSpaceRight,
            .focusTextField
        ]
    }

    private var actionKindBinding: Binding<ActionKind> {
        Binding(
            get: { ActionKind(action: current, stick: input.isAnalogStick) },
            set: { kind in
                if kind == .shortcut {
                    captureShortcut = true
                    return
                }
                captureShortcut = false
                model.store.setAction(kind.action, for: input)
            }
        )
    }
}

private enum ActionKind: Hashable {
    case unbound
    case mouseMove
    case mouseScroll
    case leftClick
    case rightClick
    case middleClick
    case shortcut
    case missionControl
    case appExpose
    case showDesktop
    case switchSpaceLeft
    case switchSpaceRight
    case focusTextField

    init(action: Action, stick: Bool) {
        switch action {
        case .unbound: self = .unbound
        case .mouseMove: self = .mouseMove
        case .mouseScroll: self = .mouseScroll
        case .mouseClickLeft: self = .leftClick
        case .mouseClickRight: self = .rightClick
        case .mouseClickMiddle: self = .middleClick
        case .keyCombo: self = .shortcut
        case .missionControl: self = .missionControl
        case .appExpose: self = .appExpose
        case .showDesktop: self = .showDesktop
        case .switchSpaceLeft: self = .switchSpaceLeft
        case .switchSpaceRight: self = .switchSpaceRight
        case .focusTextField: self = .focusTextField
        }
        if stick, self != .mouseMove, self != .mouseScroll, self != .unbound {
            self = .unbound
        }
    }

    var title: String {
        switch self {
        case .unbound: return "Unbound"
        case .mouseMove: return "Move pointer"
        case .mouseScroll: return "Scroll"
        case .leftClick: return "Left click"
        case .rightClick: return "Right click"
        case .middleClick: return "Middle click"
        case .shortcut: return "Keyboard shortcut…"
        case .missionControl: return "Mission Control"
        case .appExpose: return "App Exposé"
        case .showDesktop: return "Show Desktop"
        case .switchSpaceLeft: return "Switch Space left"
        case .switchSpaceRight: return "Switch Space right"
        case .focusTextField: return "Focus text field"
        }
    }

    var action: Action {
        switch self {
        case .unbound: return .unbound
        case .mouseMove: return .mouseMove
        case .mouseScroll: return .mouseScroll
        case .leftClick: return .mouseClickLeft
        case .rightClick: return .mouseClickRight
        case .middleClick: return .mouseClickMiddle
        case .shortcut: return .unbound
        case .missionControl: return .missionControl
        case .appExpose: return .appExpose
        case .showDesktop: return .showDesktop
        case .switchSpaceLeft: return .switchSpaceLeft
        case .switchSpaceRight: return .switchSpaceRight
        case .focusTextField: return .focusTextField
        }
    }
}
