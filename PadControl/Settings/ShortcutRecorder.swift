import AppKit
import SwiftUI

struct ShortcutRecorder: View {
    /// `nil` means no shortcut assigned yet (distinct from key A, which is code 0).
    var keyCode: UInt16?
    var flags: UInt64
    var onChange: (UInt16, UInt64) -> Void

    @State private var recording = false
    @State private var monitor: Any?
    @State private var pendingModifier: UInt16?
    @State private var pendingWork: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(recording ? "Press a key…" : display)
                    .font(.body.monospaced())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(minWidth: 140, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(recording ? Color.accentColor : Color.secondary.opacity(0.35))
                    )

                Button(recording ? "Cancel" : "Record") {
                    if recording {
                        stop()
                    } else {
                        start()
                    }
                }
            }

            Text("Single keys, chords, or hold a modifier alone (e.g. Right ⌥). Esc cancels.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            if keyCode == nil {
                start()
            }
        }
        .onDisappear { stop() }
    }

    private var display: String {
        guard let keyCode else { return "None" }
        return KeyChord.format(keyCode: keyCode, flags: CGEventFlags(rawValue: flags))
    }

    private func start() {
        stop()
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .keyDown {
                if event.keyCode == 53 {
                    stop()
                    return nil
                }
                if KeyChord.isModifierKeyCode(event.keyCode) {
                    return nil
                }
                cancelPendingModifier()
                let chordFlags = KeyChord.flags(from: event.modifierFlags)
                onChange(event.keyCode, chordFlags.rawValue)
                stop()
                return nil
            }

            if event.type == .flagsChanged {
                let code = event.keyCode
                guard KeyChord.isModifierKeyCode(code) else { return nil }

                if KeyChord.modifierIsDown(keyCode: code, flags: event.modifierFlags) {
                    // Wait before committing so ⌥A-style chords still work.
                    cancelPendingModifier()
                    pendingModifier = code
                    let work = DispatchWorkItem {
                        onChange(code, 0)
                        stop()
                    }
                    pendingWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
                } else if pendingModifier == code {
                    cancelPendingModifier()
                }
                return nil
            }

            return nil
        }
    }

    private func cancelPendingModifier() {
        pendingWork?.cancel()
        pendingWork = nil
        pendingModifier = nil
    }

    private func stop() {
        cancelPendingModifier()
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        recording = false
    }
}
