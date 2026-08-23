import SwiftUI

struct ControllerDiagramView: View {
    var lastInput: ControlInput?
    var selected: ControlInput
    var analog: AnalogState
    var deadzone: Double
    var onSelect: (ControlInput) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Click a control here, or press it on the pad.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                if let lastInput {
                    Text(lastInput.displayName)
                        .font(.caption.weight(.medium).monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
            }

            HStack(spacing: 20) {
                triggerColumn(title: "L", trigger: .leftTrigger, bumper: .leftShoulder)
                Spacer(minLength: 0)
                triggerColumn(title: "R", trigger: .rightTrigger, bumper: .rightShoulder)
            }

            HStack(alignment: .center, spacing: 20) {
                VStack(spacing: 18) {
                    dpad
                    stickPad(input: .leftStick, click: .leftThumbstickButton, vector: analog.leftStick)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 14) {
                    systemButtons
                    faceButtons
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 18) {
                    Color.clear.frame(height: 76)
                    stickPad(input: .rightStick, click: .rightThumbstickButton, vector: analog.rightStick)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.12), value: lastInput)
        .animation(.easeOut(duration: 0.12), value: selected)
    }

    private func triggerColumn(title: String, trigger: ControlInput, bumper: ControlInput) -> some View {
        VStack(spacing: 6) {
            padButton(trigger, label: "\(title)T", width: 108, height: 24, radius: 8)
            padButton(bumper, label: "\(title)B", width: 108, height: 18, radius: 5)
        }
    }

    private var dpad: some View {
        VStack(spacing: 3) {
            padButton(.dpadUp, label: "▲", width: 34, height: 28, radius: 5)
            HStack(spacing: 3) {
                padButton(.dpadLeft, label: "◀", width: 34, height: 28, radius: 5)
                padButton(.dpadRight, label: "▶", width: 34, height: 28, radius: 5)
            }
            padButton(.dpadDown, label: "▼", width: 34, height: 28, radius: 5)
        }
    }

    private var faceButtons: some View {
        VStack(spacing: 8) {
            padButton(.buttonY, label: "Y", width: 38, height: 38, circular: true, tint: Color(red: 0.86, green: 0.74, blue: 0.22))
            HStack(spacing: 30) {
                padButton(.buttonX, label: "X", width: 38, height: 38, circular: true, tint: Color(red: 0.28, green: 0.52, blue: 0.86))
                padButton(.buttonB, label: "B", width: 38, height: 38, circular: true, tint: Color(red: 0.82, green: 0.32, blue: 0.30))
            }
            padButton(.buttonA, label: "A", width: 38, height: 38, circular: true, tint: Color(red: 0.30, green: 0.68, blue: 0.38))
        }
    }

    private var systemButtons: some View {
        HStack(spacing: 8) {
            padButton(.buttonOptions, label: "Opt", width: 46, height: 22, radius: 11)
            padButton(.buttonHome, label: "Home", width: 54, height: 22, radius: 11)
            padButton(.buttonMenu, label: "Menu", width: 46, height: 22, radius: 11)
        }
    }

    private func stickPad(input: ControlInput, click: ControlInput, vector: SIMD2<Float>) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(fill(for: input))
                    .overlay(Circle().strokeBorder(border(for: input), lineWidth: selected == input || lastInput == input ? 2 : 1))
                    .frame(width: 78, height: 78)
                    .contentShape(Circle())
                    .onTapGesture { onSelect(input) }

                Circle()
                    .strokeBorder(Color.primary.opacity(0.18), lineWidth: 1)
                    .frame(width: CGFloat(deadzone) * 78, height: CGFloat(deadzone) * 78)

                Circle()
                    .fill(.primary.opacity(0.82))
                    .frame(width: 16, height: 16)
                    .offset(
                        x: CGFloat(vector.x) * 24,
                        y: CGFloat(-vector.y) * 24
                    )
                    .allowsHitTesting(false)
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(input.displayName)
            padButton(click, label: "Click", width: 52, height: 18, radius: 5)
        }
    }

    private func padButton(
        _ input: ControlInput,
        label: String,
        width: CGFloat,
        height: CGFloat,
        circular: Bool = false,
        radius: CGFloat = 6,
        tint: Color? = nil
    ) -> some View {
        let active = selected == input || lastInput == input
        return Text(label)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .frame(width: width, height: height)
            .background(fill(for: input, tint: tint), in: shape(circular: circular, radius: radius))
            .overlay(shape(circular: circular, radius: radius).strokeBorder(border(for: input), lineWidth: selected == input ? 2 : 1))
            .scaleEffect(lastInput == input ? 0.96 : 1)
            .shadow(color: active ? Color.accentColor.opacity(0.18) : .clear, radius: 6, y: 1)
            .contentShape(shape(circular: circular, radius: radius))
            .onTapGesture { onSelect(input) }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(input.displayName)
    }

    private func shape(circular: Bool, radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: circular ? 20 : radius, style: .continuous)
    }

    private func fill(for input: ControlInput, tint: Color? = nil) -> Color {
        if selected == input {
            return Color.accentColor.opacity(0.30)
        }
        if lastInput == input {
            return Color.accentColor.opacity(0.16)
        }
        if let tint {
            return tint.opacity(0.22)
        }
        return Color.primary.opacity(0.06)
    }

    private func border(for input: ControlInput) -> Color {
        if selected == input || lastInput == input {
            return Color.accentColor.opacity(0.9)
        }
        return Color.primary.opacity(0.14)
    }
}
