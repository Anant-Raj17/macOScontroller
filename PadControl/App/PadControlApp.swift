import SwiftUI

@main
struct PadControlApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(model)
        } label: {
            Image(systemName: menuIcon)
                .symbolRenderingMode(.hierarchical)
        }

        Settings {
            SettingsView()
                .environmentObject(model)
                .frame(minWidth: SettingsView.windowSize.width, minHeight: SettingsView.windowSize.height)
        }
        .defaultSize(width: SettingsView.windowSize.width, height: SettingsView.windowSize.height)
    }

    private var menuIcon: String {
        if !model.isTrusted {
            return "exclamationmark.triangle"
        }
        if model.mappingEnabled, model.controllerName != nil {
            return "gamecontroller.fill"
        }
        return "gamecontroller"
    }
}
