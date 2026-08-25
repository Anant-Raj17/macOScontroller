import SwiftUI

@main
struct PadControlApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(model)
        } label: {
            if !model.isTrusted {
                Image(systemName: "exclamationmark.triangle")
                    .symbolRenderingMode(.hierarchical)
            } else {
                Text("🎮")
                    .opacity(model.mappingEnabled && model.controllerName != nil ? 1 : 0.55)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(model)
                .frame(minWidth: SettingsView.windowSize.width, minHeight: SettingsView.windowSize.height)
        }
        .defaultSize(width: SettingsView.windowSize.width, height: SettingsView.windowSize.height)
    }
}
