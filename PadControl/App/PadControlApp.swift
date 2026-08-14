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
                .frame(minWidth: 640, minHeight: 520)
        }
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
