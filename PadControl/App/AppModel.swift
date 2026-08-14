import AppKit
import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var mappingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(mappingEnabled, forKey: Self.mappingKey)
            engine.enabled = mappingEnabled
            if !mappingEnabled {
                engine.stop()
            } else {
                engine.analogDidChange()
            }
            updateActivity()
        }
    }

    @Published var isTrusted = false
    @Published var launchAtLogin = false

    let controllers = ControllerManager()
    let store = ProfileStore()
    let engine = MappingEngine()

    private var cancellables = Set<AnyCancellable>()
    private var trustTimer: Timer?
    private var activity: NSObjectProtocol?

    private static let mappingKey = "mappingEnabled"

    init() {
        mappingEnabled = UserDefaults.standard.object(forKey: Self.mappingKey) as? Bool ?? true
        engine.enabled = mappingEnabled
        engine.profile = store.profile
        let manager = controllers
        engine.analogProvider = { [weak manager] in
            manager?.analog ?? .zero
        }
        engine.isTrusted = { [weak self] in
            self?.isTrusted ?? false
        }

        controllers.onDigital = { [weak self] input, pressed in
            self?.engine.handleDigital(input, pressed: pressed)
        }
        controllers.onAnalogChanged = { [weak self] in
            self?.engine.analogDidChange()
        }

        controllers.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        store.$profile
            .sink { [weak self] profile in
                self?.engine.profile = profile
            }
            .store(in: &cancellables)

        isTrusted = AccessibilityGate.isTrusted()
        launchAtLogin = SMAppService.mainApp.status == .enabled
        trustTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshTrust()
            }
        }
        updateActivity()
    }

    var controllerName: String? { controllers.controllerName }
    var lastInput: ControlInput? { controllers.lastInput }

    func refreshTrust() {
        let trusted = AccessibilityGate.isTrusted()
        if trusted != isTrusted {
            isTrusted = trusted
            engine.analogDidChange()
        }
    }

    func requestAccessibility() {
        AccessibilityGate.promptIfNeeded()
        AccessibilityGate.openSystemSettings()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } catch {
            NSLog("PadControl: launch at login failed: \(error.localizedDescription)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func updateActivity() {
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
        guard mappingEnabled else { return }
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical],
            reason: "PadControl mapping"
        )
    }
}
