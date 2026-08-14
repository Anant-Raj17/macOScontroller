import AppKit
import ApplicationServices

final class TextFieldFocuser {
    private let overlay = HighlightOverlay()
    private var lastPID: pid_t = 0
    private var lastWindowID: String = ""
    private var cycleIndex = 0
    private let mouse = MouseInjector()

    func focusNext() {
        guard let window = focusedWindow() else { return }
        let windowID = identity(of: window)
        let pid = frontmostPID() ?? 0
        if pid != lastPID || windowID != lastWindowID {
            lastPID = pid
            lastWindowID = windowID
            cycleIndex = 0
        }

        let fields = collectTextFields(in: window)
        guard !fields.isEmpty else { return }

        let field = fields[cycleIndex % fields.count]
        cycleIndex = (cycleIndex + 1) % fields.count

        if let frame = quartzFrame(of: field) {
            overlay.show(quartzRect: frame)
        }
        focus(field)
    }

    private func focusedWindow() -> AXUIElement? {
        guard let pid = frontmostPID() else { return nil }
        let app = AXUIElementCreateApplication(pid)
        return copyElement(app, attribute: kAXFocusedWindowAttribute as String)
            ?? copyElement(app, attribute: kAXMainWindowAttribute as String)
    }

    private func frontmostPID() -> pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }

    private func collectTextFields(in window: AXUIElement) -> [AXUIElement] {
        var found: [AXUIElement] = []
        walk(window, depth: 0, into: &found)
        return found.sorted { lhs, rhs in
            let a = cocoaFrame(of: lhs) ?? .zero
            let b = cocoaFrame(of: rhs) ?? .zero
            if abs(a.minY - b.minY) > 8 {
                return a.minY > b.minY
            }
            return a.minX < b.minX
        }
    }

    private func walk(_ element: AXUIElement, depth: Int, into result: inout [AXUIElement]) {
        guard depth < 24, result.count < 80 else { return }
        let role = stringValue(element, attribute: kAXRoleAttribute as String) ?? ""
        if Self.skippedRoles.contains(role) { return }

        if isCandidate(element, role: role) {
            result.append(element)
        }

        guard let children = copyArray(element, attribute: kAXChildrenAttribute as String) else { return }
        for child in children {
            walk(child, depth: depth + 1, into: &result)
        }
    }

    private func isCandidate(_ element: AXUIElement, role: String) -> Bool {
        if Self.secureRoles.contains(role) { return false }
        let subrole = stringValue(element, attribute: kAXSubroleAttribute as String) ?? ""
        if Self.secureRoles.contains(subrole) { return false }
        guard Self.textRoles.contains(role) else { return false }
        if boolValue(element, attribute: kAXEnabledAttribute as String) == false { return false }
        if boolValue(element, attribute: kAXHiddenAttribute as String) == true { return false }
        guard let frame = cocoaFrame(of: element), frame.width > 8, frame.height > 8 else { return false }
        return true
    }

    private func focus(_ element: AXUIElement) {
        let focused = AXUIElementSetAttributeValue(
            element,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )
        if focused == .success { return }

        AXUIElementPerformAction(element, kAXPressAction as CFString)
        if let frame = quartzFrame(of: element) {
            let point = CGPoint(x: frame.midX, y: frame.midY)
            mouse.click(at: point)
        }
    }

    private func identity(of element: AXUIElement) -> String {
        let title = stringValue(element, attribute: kAXTitleAttribute as String) ?? ""
        let role = stringValue(element, attribute: kAXRoleAttribute as String) ?? ""
        let frame = cocoaFrame(of: element) ?? .zero
        return "\(role)|\(title)|\(Int(frame.origin.x))|\(Int(frame.origin.y))|\(Int(frame.width))|\(Int(frame.height))"
    }

    private func quartzFrame(of element: AXUIElement) -> CGRect? {
        guard let position = copyPoint(element, attribute: kAXPositionAttribute as String),
              let size = copySize(element, attribute: kAXSizeAttribute as String) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    private func cocoaFrame(of element: AXUIElement) -> CGRect? {
        guard let quartz = quartzFrame(of: element) else { return nil }
        let height = NSScreen.screens.first { $0.frame.origin == .zero }?.frame.height
            ?? NSScreen.main?.frame.height
            ?? 0
        return CGRect(
            x: quartz.origin.x,
            y: height - quartz.origin.y - quartz.height,
            width: quartz.width,
            height: quartz.height
        )
    }

    private func copyElement(_ element: AXUIElement, attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let value else { return nil }
        return (value as! AXUIElement)
    }

    private func copyArray(_ element: AXUIElement, attribute: String) -> [AXUIElement]? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let array = value as? NSArray else { return nil }
        return array.map { $0 as! AXUIElement }
    }

    private func stringValue(_ element: AXUIElement, attribute: String) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value as? String
    }

    private func boolValue(_ element: AXUIElement, attribute: String) -> Bool? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return (value as? Bool)
    }

    private func copyPoint(_ element: AXUIElement, attribute: String) -> CGPoint? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let ax = value else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(ax as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func copySize(_ element: AXUIElement, attribute: String) -> CGSize? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let ax = value else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(ax as! AXValue, .cgSize, &size) else { return nil }
        return size
    }

    private static let textRoles: Set<String> = [
        kAXTextFieldRole as String,
        kAXTextAreaRole as String,
        kAXComboBoxRole as String,
        "AXSearchField"
    ]

    private static let secureRoles: Set<String> = [
        kAXSecureTextFieldSubrole as String,
        "AXSecureTextField"
    ]

    private static let skippedRoles: Set<String> = [
        kAXMenuRole as String,
        kAXMenuBarRole as String,
        kAXMenuItemRole as String,
        "AXMenuButton"
    ]
}
