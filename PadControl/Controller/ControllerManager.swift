import Foundation
import GameController

final class ControllerManager: ObservableObject {
    @Published private(set) var controllerName: String?
    @Published private(set) var lastInput: ControlInput?
    @Published private(set) var analog = AnalogState()

    var onDigital: ((ControlInput, Bool) -> Void)?
    var onAnalogChanged: (() -> Void)?

    private var observers: [NSObjectProtocol] = []

    init() {
        GCController.shouldMonitorBackgroundEvents = true
        GCController.startWirelessControllerDiscovery(completionHandler: nil)

        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        })
        observers.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        })

        refresh()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        GCController.stopWirelessControllerDiscovery()
    }

    func refresh() {
        let controller = preferredController()
        controllerName = controller.flatMap { $0.vendorName ?? $0.productCategory }
        analog = .zero
        attach(to: controller)
        onAnalogChanged?()
    }

    private func preferredController() -> GCController? {
        GCController.controllers().first { $0.extendedGamepad != nil }
            ?? GCController.controllers().first
    }

    private func attach(to controller: GCController?) {
        guard let gamepad = controller?.extendedGamepad else {
            return
        }

        bind(gamepad.buttonA, input: .buttonA)
        bind(gamepad.buttonB, input: .buttonB)
        bind(gamepad.buttonX, input: .buttonX)
        bind(gamepad.buttonY, input: .buttonY)
        bind(gamepad.leftShoulder, input: .leftShoulder)
        bind(gamepad.rightShoulder, input: .rightShoulder)
        bind(gamepad.leftTrigger, input: .leftTrigger)
        bind(gamepad.rightTrigger, input: .rightTrigger)
        bind(gamepad.buttonMenu, input: .buttonMenu)
        if let options = gamepad.buttonOptions {
            bind(options, input: .buttonOptions)
        }
        if let home = gamepad.buttonHome {
            bind(home, input: .buttonHome)
        }
        if let leftClick = gamepad.leftThumbstickButton {
            bind(leftClick, input: .leftThumbstickButton)
        }
        if let rightClick = gamepad.rightThumbstickButton {
            bind(rightClick, input: .rightThumbstickButton)
        }

        bind(gamepad.dpad.up, input: .dpadUp)
        bind(gamepad.dpad.down, input: .dpadDown)
        bind(gamepad.dpad.left, input: .dpadLeft)
        bind(gamepad.dpad.right, input: .dpadRight)

        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            guard let self else { return }
            self.analog.leftStick = SIMD2(x, y)
            if hypot(x, y) > 0.2 {
                self.lastInput = .leftStick
            }
            self.onAnalogChanged?()
        }
        gamepad.rightThumbstick.valueChangedHandler = { [weak self] _, x, y in
            guard let self else { return }
            self.analog.rightStick = SIMD2(x, y)
            if hypot(x, y) > 0.2 {
                self.lastInput = .rightStick
            }
            self.onAnalogChanged?()
        }
    }

    private func bind(_ button: GCControllerButtonInput, input: ControlInput) {
        button.pressedChangedHandler = { [weak self] _, _, pressed in
            guard let self else { return }
            if pressed {
                self.lastInput = input
            }
            self.onDigital?(input, pressed)
        }
    }
}
