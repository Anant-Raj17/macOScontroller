import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralPane()
                .tabItem { Label("General", systemImage: "gearshape") }
            MappingPane()
                .tabItem { Label("Mapping", systemImage: "gamecontroller") }
            SticksPane()
                .tabItem { Label("Sticks", systemImage: "l.joystick") }
        }
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
        .frame(width: 520, height: 460)
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
        .frame(minWidth: 760, minHeight: 620)
        .onChange(of: model.lastInput) { _, input in
            if let input {
                selectedInput = input
            }
        }
    }

    private var bindingsList: some View {
        List(selection: Binding(
            get: { Optional(selectedInput) },
            set: { if let value = $0 { selectedInput = value } }
        )) {
            ForEach(ControlInput.Group.allCases) { group in
                Section(group.title) {
                    ForEach(ControlInput.allCases.filter { $0.group == group }) { input in
                        HStack(spacing: 10) {
                            Text(input.shortLabel)
                                .font(.body.weight(.medium))
                            Spacer(minLength: 8)
                            Text(model.store.profile.action(for: input).displayName)
                                .foregroundStyle(model.store.profile.action(for: input) == .unbound ? .tertiary : .secondary)
                                .font(.callout.monospaced())
                        }
                        .tag(input)
                        .listRowBackground(
                            input == model.lastInput
                                ? Color.accentColor.opacity(0.12)
                                : Color.clear
                        )
                        .accessibilityLabel("\(input.displayName), \(model.store.profile.action(for: input).displayName)")
                    }
                }
            }
        }
        .listStyle(.inset)
        .frame(minWidth: 280)
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
        .frame(width: 520, height: 480)
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
