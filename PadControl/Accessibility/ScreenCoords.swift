import AppKit

enum ScreenCoords {
    /// Height of the display whose frame origin is (0, 0) — the shared Quartz/Cocoa Y pivot.
    static var primaryHeight: CGFloat {
        NSScreen.screens.first { $0.frame.origin == .zero }?.frame.height
            ?? NSScreen.main?.frame.height
            ?? 0
    }

    static func cocoaRect(fromQuartz rect: CGRect) -> CGRect {
        let height = primaryHeight
        return CGRect(
            x: rect.origin.x,
            y: height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    static func quartzRect(fromCocoa rect: CGRect) -> CGRect {
        let height = primaryHeight
        return CGRect(
            x: rect.origin.x,
            y: height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}
