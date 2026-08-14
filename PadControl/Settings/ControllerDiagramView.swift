import SwiftUI

struct ControllerDiagramView: View {
    var lastInput: ControlInput?
    var selected: ControlInput
    var analog: AnalogState
    var deadzone: Double
    var onSelect: (ControlInput) -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 28) {
                triggerColumn(title: "L", trigger: .leftTrigger, bumper: .leftShoulder)
                Spacer(minLength: 0)
                triggerColumn(title: "R", trigger: .rightTrigger, bumper: .rightShoulder)
            }

            HStack(alignment: .center, spacing: 24) {
                VStack(spacing: 16) {
                    dpad
                    stickPad(input: .leftStick, click: .leftThumbstickButton, vector: analog.leftStick)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    systemButtons
                    faceButtons
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 16) {
                    Color.clear.frame(height: 72)
                    stickPad(input: .rightStick, click: .rightThumbstickButton, vector: analog.rightStick)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 1)
        )
    }

    private func triggerColumn(title: String, trigger: ControlInput, bumper: ControlInput) -> some View {
        VStack(spacing: 6) {
            padButton(trigger, label: "\(title)T", width: 92, height: 22)
            padButton(bumper, label: "\(title)B", width: 92, height: 18)
        }
    }

    private var dpad: some View {
        VStack(spacing: 4) {
            padButton(.dpadUp, label: "▲", width: 36, height: 28)
            HStack(spacing: 4) {
                padButton(.dpadLeft, label: "◀", width: 36, height: 28)
                padButton(.dpadRight, label: "▶", width: 36, height: 28)
            }
            padButton(.dpadDown, label: "▼", width: 36, height: 28)
        }
    }

    private var faceButtons: some View {
        VStack(spacing: 6) {
            padButton(.buttonY, label: "Y", width: 36, height: 36, circular: true)
            HStack(spacing: 28) {
                padButton(.buttonX, label: "X", width: 36, height: 36, circular: true)
                padButton(.buttonB, label: "B", width: 36, height: 36, circular: true)
            }
            padButton(.buttonA, label: "A", width: 36, height: 36, circular: true)
        }
    }

    private var systemButtons: some View {
        HStack(spacing: 8) {
            padButton(.buttonOptions, label: "Opt", width: 44, height: 20)
            padButton(.buttonHome, label: "Home", width: 52, height: 20)
            padButton(.buttonMenu, label: "Menu", width: 44, height: 20)
        }
    }

    private func stickPad(input: ControlInput, click: ControlInput, vector: SIMD2<Float>) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(fill(for: input))
                    .overlay(Circle().strokeBorder(border(for: input), lineWidth: selected == input || lastInput == input ? 2 : 1))
                    .frame(width: 74, height: 74)
                    .onTapGesture { onSelect(input) }

                Circle()
                    .fill(.primary.opacity(0.8))
                    .frame(width: 18, height: 18)
                    .offset(
                        x: CGFloat(vector.x) * 22,
                        y: CGFloat(-vector.y) * 22
                    )
                    .allowsHitTesting(false)
            }
            padButton(click, label: "Click", width: 52, height: 18)
        }
    }

    private func padButton(_ input: ControlInput, label: String, width: CGFloat, height: CGFloat, circular: Bool = false) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .frame(width: width, height: height)
            .background(fill(for: input), in: shape(circular: circular))
            .overlay(shape(circular: circular).strokeBorder(border(for: input), lineWidth: selected == input ? 2 : 1))
            .onTapGesture { onSelect(input) }
            .accessibilityLabel(input.displayName)
    }

    private func shape(circular: Bool) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: circular ? 20 : 6, style: .continuous)
    }

    private func fill(for input: ControlInput) -> Color {
        if selected == input {
            return Color.accentColor.opacity(0.28)
        }
        if lastInput == input {
            return Color.accentColor.opacity(0.16)
        }
        return Color.primary.opacity(0.06)
    }

    private func border(for input: ControlInput) -> Color {
        if selected == input || lastInput == input {
            return Color.accentColor.opacity(0.9)
        }
        return Color.primary.opacity(0.15)
    }
}
