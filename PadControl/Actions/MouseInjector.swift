import AppKit
import CoreGraphics

final class MouseInjector {
    private let source = CGEventSource(stateID: .hidSystemState)
    private(set) var heldButton: CGMouseButton?

    func move(dx: Double, dy: Double) {
        let current = CGEvent(source: nil)?.location ?? .zero
        var next = CGPoint(x: current.x + dx, y: current.y + dy)
        next = clampToDisplays(next)
        postMouse(type: dragType, button: heldButton ?? .left, at: next, deltaX: dx, deltaY: dy)
    }

    func down(_ button: CGMouseButton) {
        heldButton = button
        postMouse(type: downType(button), button: button, at: location)
    }

    func up(_ button: CGMouseButton) {
        postMouse(type: upType(button), button: button, at: location)
        if heldButton == button {
            heldButton = nil
        }
    }

    func scroll(dx: Double, dy: Double) {
        let wheelY = Int32(dy.rounded())
        let wheelX = Int32(dx.rounded())
        guard wheelY != 0 || wheelX != 0 else { return }
        guard let event = CGEvent(
            scrollWheelEvent2Source: source,
            units: .pixel,
            wheelCount: 2,
            wheel1: wheelY,
            wheel2: wheelX,
            wheel3: 0
        ) else { return }
        stamp(event)
        event.post(tap: .cghidEventTap)
    }

    func click(at point: CGPoint, button: CGMouseButton = .left) {
        postMouse(type: downType(button), button: button, at: point)
        postMouse(type: upType(button), button: button, at: point)
    }

    private var location: CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    private var dragType: CGEventType {
        switch heldButton {
        case .left: return .leftMouseDragged
        case .right: return .rightMouseDragged
        case .center: return .otherMouseDragged
        default: return .mouseMoved
        }
    }

    private func downType(_ button: CGMouseButton) -> CGEventType {
        switch button {
        case .left: return .leftMouseDown
        case .right: return .rightMouseDown
        default: return .otherMouseDown
        }
    }

    private func upType(_ button: CGMouseButton) -> CGEventType {
        switch button {
        case .left: return .leftMouseUp
        case .right: return .rightMouseUp
        default: return .otherMouseUp
        }
    }

    private func postMouse(type: CGEventType, button: CGMouseButton, at point: CGPoint, deltaX: Double = 0, deltaY: Double = 0) {
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: button
        ) else { return }
        event.setIntegerValueField(.mouseEventDeltaX, value: Int64(deltaX.rounded()))
        event.setIntegerValueField(.mouseEventDeltaY, value: Int64(deltaY.rounded()))
        stamp(event)
        event.post(tap: .cghidEventTap)
    }

    private func stamp(_ event: CGEvent) {
        event.timestamp = CGEventTimestamp(ProcessInfo.processInfo.systemUptime * 1_000_000_000)
    }

    private func clampToDisplays(_ point: CGPoint) -> CGPoint {
        var bounds = CGRect.null
        for screen in NSScreen.screens {
            bounds = bounds.union(quartzRect(fromCocoa: screen.frame))
        }
        guard !bounds.isNull, !bounds.isEmpty else { return point }
        return CGPoint(
            x: min(max(point.x, bounds.minX), bounds.maxX - 1),
            y: min(max(point.y, bounds.minY), bounds.maxY - 1)
        )
    }

    private func quartzRect(fromCocoa rect: CGRect) -> CGRect {
        ScreenCoords.quartzRect(fromCocoa: rect)
    }
}
