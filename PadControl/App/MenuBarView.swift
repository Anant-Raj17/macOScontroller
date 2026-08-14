import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle("Enable mapping", isOn: $model.mappingEnabled)
                .disabled(!model.isTrusted)

            if let name = model.controllerName {
                Text(name)
                    .foregroundStyle(.secondary)
            } else {
                Text("No controller connected")
                    .foregroundStyle(.secondary)
            }

            if !model.isTrusted {
                Divider()
                Button("Grant Accessibility…") {
                    model.requestAccessibility()
                }
            }

            Divider()

            Button("Settings…") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit PadControl") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.vertical, 4)
    }
}
