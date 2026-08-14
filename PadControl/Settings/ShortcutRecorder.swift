import AppKit
import SwiftUI

struct ShortcutRecorder: View {
    var keyCode: UInt16
    var flags: UInt64
    var onChange: (UInt16, UInt64) -> Void

    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 10) {
            Text(recording ? "Press a shortcut…" : display)
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
        .onDisappear { stop() }
    }

    private var display: String {
        if keyCode == 0 && flags == 0 {
            return "None"
        }
        return KeyChord.format(keyCode: keyCode, flags: CGEventFlags(rawValue: flags))
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.keyCode == 53 {
                stop()
                return nil
            }
            let chordFlags = KeyChord.flags(from: event.modifierFlags)
            onChange(event.keyCode, chordFlags.rawValue)
            stop()
            return nil
        }
    }

    private func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        recording = false
    }
}
