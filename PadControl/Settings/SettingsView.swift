import SwiftUI

struct SettingsView: View {
    static let windowSize = CGSize(width: 760, height: 620)

    var body: some View {
        TabView {
            GeneralPane()
                .tabItem { Label("General", systemImage: "gearshape") }
            MappingPane()
                .tabItem { Label("Mapping", systemImage: "gamecontroller") }
            SticksPane()
                .tabItem { Label("Sticks", systemImage: "l.joystick") }
        }
        .frame(minWidth: Self.windowSize.width, minHeight: Self.windowSize.height)
    }
}

private struct GeneralPane: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section {
                LabeledContent("Pad") {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(model.controllerName == nil ? Color.secondary.opacity(0.35) : Color.green)
                            .frame(width: 7, height: 7)
                        Text(model.controllerName ?? "None connected")
                            .foregroundStyle(model.controllerName == nil ? .secondary : .primary)
                    }
                }
                Toggle("Enable mapping", isOn: $model.mappingEnabled)
                    .disabled(!model.isTrusted)
            } header: {
                Text("Controller")
            } footer: {
                if !model.isTrusted {
                    Text("Mapping stays off until Accessibility is granted.")
                } else if model.controllerName == nil {
                    Text("Connect a pad macOS already sees. Xbox, DualSense, Switch Pro, and 8BitDo in XInput mode all work.")
                }
            }

            Section {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
            } header: {
                Text("Startup")
            }

            Section {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: model.isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(model.isTrusted ? Color.green : Color.orange)
                        .imageScale(.large)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.isTrusted ? "Accessibility is granted" : "Accessibility is required")
                            .font(.body.weight(.medium))
                        Text("PadControl posts mouse and keyboard events and reads the focused window’s accessibility tree. macOS blocks that until this app is enabled in Privacy & Security.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if !model.isTrusted {
                            Button("Open Accessibility Settings") {
                                model.requestAccessibility()
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            } header: {
                Text("Permissions")
            }

            Section {
                Button("Reset bindings to defaults") {
                    model.store.resetToDefaults()
                }
                .disabled(model.store.profile == .default)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { model.launchAtLogin },
            set: { model.setLaunchAtLogin($0) }
        )
    }
}

private struct MappingPane: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedInput: ControlInput = .buttonA

    var body: some View {
        VStack(spacing: 0) {
            ControllerDiagramView(
                lastInput: model.lastInput,
                selected: selectedInput,
                analog: model.controllers.analog,
                deadzone: model.store.profile.deadzone
            ) { selectedInput = $0 }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider()

            HStack(alignment: .top, spacing: 0) {
                ActionPicker(input: selectedInput)
                    .environmentObject(model)
                    .padding(20)
                    .frame(minWidth: 280, idealWidth: 300, maxWidth: 340, alignment: .topLeading)

                Divider()

                bindingsList
                    .padding(.vertical, 12)
                    .padding(.trailing, 8)
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: model.lastInput) { _, input in
            if let input {
                selectedInput = input
            }
        }
    }

    private var bindingsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(ControlInput.Group.allCases) { group in
                    bindingsGroup(group)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(minWidth: 280)
    }

    private func bindingsGroup(_ group: ControlInput.Group) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            VStack(spacing: 0) {
                ForEach(ControlInput.allCases.filter { $0.group == group }) { input in
                    bindingRow(input)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private func bindingRow(_ input: ControlInput) -> some View {
        let action = model.store.profile.action(for: input)
        let isMapped = action != .unbound
        let isSelected = input == selectedInput
        let isActive = input == model.lastInput

        return Button(action: { selectedInput = input }) {
            HStack(spacing: 10) {
                Image(systemName: input.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(input.shortLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : .primary)

                    if isMapped {
                        Text(action.displayName)
                            .font(.caption.monospaced())
                            .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Unbound")
                            .font(.caption)
                            .foregroundStyle(isSelected ? Color.white.opacity(0.6) : Color.secondary.opacity(0.5))
                            .italic()
                    }
                }

                Spacer(minLength: 8)

                if isMapped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? .white : Color.green.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        isActive
                            ? Color.accentColor.opacity(0.15)
                            : isSelected
                                ? Color.accentColor
                                : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("\(input.displayName), \(action.displayName)")
    }
}

private struct SticksPane: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section {
                labeledSlider("Deadzone", value: deadzoneBinding, range: 0.04...0.4, format: "%.2f")
                labeledSlider("Pointer speed", value: mouseSpeedBinding, range: 4...40, format: "%.0f")
                labeledSlider("Scroll speed", value: scrollSpeedBinding, range: 1...20, format: "%.0f")
            } header: {
                Text("Feel")
            } footer: {
                Text("Deadzone ignores stick noise. Pointer and scroll speeds apply when a stick is mapped to those actions.")
            }

            Section {
                HStack(spacing: 28) {
                    stickMeter(title: "Left", vector: model.controllers.analog.leftStick)
                    stickMeter(title: "Right", vector: model.controllers.analog.rightStick)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } header: {
                Text("Live")
            } footer: {
                Text("Move the sticks to see output after the deadzone.")
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func stickMeter(title: String, vector: SIMD2<Float>) -> some View {
        let dz = Float(model.store.profile.deadzone)
        let mag = hypot(vector.x, vector.y)
        let live = mag > dz
        return VStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ZStack {
                Circle()
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                Circle()
                    .strokeBorder(Color.primary.opacity(0.22), lineWidth: 1)
                    .padding(CGFloat((1 - model.store.profile.deadzone) * 36))
                Circle()
                    .fill(live ? Color.accentColor : Color.primary.opacity(0.85))
                    .frame(width: 12, height: 12)
                    .offset(
                        x: CGFloat(vector.x) * 36,
                        y: CGFloat(-vector.y) * 36
                    )
            }
            .frame(width: 88, height: 88)
            Text(String(format: "x %.2f  y %.2f", vector.x, vector.y))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var deadzoneBinding: Binding<Double> {
        Binding(
            get: { model.store.profile.deadzone },
            set: { value in
                var profile = model.store.profile
                profile.deadzone = value
                model.store.profile = profile
            }
        )
    }

    private var mouseSpeedBinding: Binding<Double> {
        Binding(
            get: { model.store.profile.mouseSpeed },
            set: { value in
                var profile = model.store.profile
                profile.mouseSpeed = value
                model.store.profile = profile
            }
        )
    }

    private var scrollSpeedBinding: Binding<Double> {
        Binding(
            get: { model.store.profile.scrollSpeed },
            set: { value in
                var profile = model.store.profile
                profile.scrollSpeed = value
                model.store.profile = profile
            }
        )
    }

    private func labeledSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range)
        }
        .padding(.vertical, 2)
    }
}
