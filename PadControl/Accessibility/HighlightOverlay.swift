import AppKit

final class HighlightOverlay {
    private var window: NSWindow?
    private var hideWork: DispatchWorkItem?

    func show(quartzRect: CGRect) {
        let cocoa = cocoaRect(fromQuartz: quartzRect).insetBy(dx: -3, dy: -3)
        let panel = window ?? makeWindow()
        window = panel
        panel.setFrame(cocoa, display: true)
        panel.contentView?.needsDisplay = true
        panel.orderFrontRegardless()

        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.window?.orderOut(nil)
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85, execute: work)
    }

    private func makeWindow() -> NSWindow {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.contentView = StrokeView(frame: .zero)
        return panel
    }

    private func cocoaRect(fromQuartz rect: CGRect) -> CGRect {
        let height = NSScreen.screens.first { $0.frame.origin == .zero }?.frame.height
            ?? NSScreen.main?.frame.height
            ?? 0
        return CGRect(
            x: rect.origin.x,
            y: height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}

private final class StrokeView: NSView {
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 6, yRadius: 6)
        path.lineWidth = 3
        NSColor.systemYellow.withAlphaComponent(0.95).setStroke()
        path.stroke()
        NSColor.systemYellow.withAlphaComponent(0.12).setFill()
        path.fill()
    }
}
