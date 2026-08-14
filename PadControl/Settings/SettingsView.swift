import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedInput: ControlInput = .buttonA

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 16) {
                generalSection
                stickSection
                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(minWidth: 280, idealWidth: 300, maxWidth: 340)

            VStack(alignment: .leading, spacing: 16) {
                ControllerDiagramView(
                    lastInput: model.lastInput,
                    selected: selectedInput,
                    analog: model.controllers.analog,
                    deadzone: model.store.profile.deadzone
                ) { selectedInput = $0 }

                ActionPicker(input: selectedInput)
                    .environmentObject(model)

                bindingsList
            }
            .padding(20)
            .frame(minWidth: 360)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PadControl")
                .font(.title2.weight(.semibold))
            Text("Map a controller to pointer, clicks, shortcuts, and text fields.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LabeledContent("Controller") {
                Text(model.controllerName ?? "None")
                    .foregroundStyle(model.controllerName == nil ? .secondary : .primary)
            }

            Toggle("Enable mapping", isOn: $model.mappingEnabled)
                .disabled(!model.isTrusted)

            Toggle("Launch at login", isOn: launchAtLoginBinding)

            accessibilityRow

            Button("Reset bindings to defaults") {
                model.store.resetToDefaults()
            }
            .disabled(model.store.profile == .default)
        }
    }

    private var accessibilityRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: model.isTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(model.isTrusted ? Color.green : Color.orange)
                Text(model.isTrusted ? "Accessibility is granted" : "Accessibility is required")
                    .font(.callout)
            }
            if !model.isTrusted {
                Text("PadControl posts mouse and keyboard events and reads the focused window’s accessibility tree. macOS will not deliver those events until this app is enabled in Privacy & Security.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Accessibility Settings") {
                    model.requestAccessibility()
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var stickSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stick feel")
                .font(.headline)
            labeledSlider("Deadzone", value: deadzoneBinding, range: 0.04...0.4, format: "%.2f")
            labeledSlider("Pointer speed", value: mouseSpeedBinding, range: 4...40, format: "%.0f")
            labeledSlider("Scroll speed", value: scrollSpeedBinding, range: 1...20, format: "%.0f")
        }
    }

    private var bindingsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bindings")
                .font(.headline)
            List(ControlInput.allCases, selection: Binding(
                get: { Optional(selectedInput) },
                set: { if let value = $0 { selectedInput = value } }
            )) { input in
                HStack {
                    Text(input.displayName)
                    Spacer()
                    Text(model.store.profile.action(for: input).displayName)
                        .foregroundStyle(.secondary)
                }
                .tag(input)
                .listRowBackground(
                    input == model.lastInput
                        ? Color.accentColor.opacity(0.12)
                        : Color.clear
                )
            }
            .listStyle(.inset)
            .frame(minHeight: 180)
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { model.launchAtLogin },
            set: { model.setLaunchAtLogin($0) }
        )
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.callout)
            Slider(value: value, in: range)
        }
    }
}
