import AppKit

/// Utility for capturing screenshots of accessibility elements or windows.
public enum ScreenshotCapture {

    /// Capture a screenshot of the window containing the given element (out-of-process).
    /// Uses `CGWindowListCreateImage` to capture without requiring screen recording permission.
    public static func capture(window element: AXElement) -> NSImage? {
        let pid = element.pid
        return capture(pid: pid)
    }

    /// Capture the frontmost window of the given process.
    public static func capture(pid: pid_t) -> NSImage? {
        guard let windowInfo = findWindow(for: pid) else { return nil }
        guard let windowID = windowInfo[kCGWindowNumber as String] as? UInt32 else { return nil }

        let image = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .shouldBeOpaque]
        )
        guard let cgImage = image else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    /// Capture an NSWindow (in-process, for component tests).
    public static func capture(nsWindow: NSWindow) -> NSImage? {
        guard let contentView = nsWindow.contentView else { return nil }
        let bounds = contentView.bounds
        guard let bitmapRep = contentView.bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        contentView.cacheDisplay(in: bounds, to: bitmapRep)
        guard let cgImage = bitmapRep.cgImage else { return nil }
        return NSImage(cgImage: cgImage, size: nsWindow.frame.size)
    }

    /// Save an NSImage to disk as PNG.
    @discardableResult
    public static func save(
        _ image: NSImage,
        to url: URL,
        as type: NSBitmapImageRep.FileType = .png
    ) throws -> URL {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: type, properties: [:]) else {
            throw NSError(domain: "ScreenshotCapture", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create image data"])
        }
        try data.write(to: url)
        return url
    }

    // MARK: - Private

    private static func findWindow(for pid: pid_t) -> [String: Any]? {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }

        // Find the frontmost window for the given PID
        return windowList.first { info in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t else { return false }
            return ownerPID == pid && (info[kCGWindowLayer as String] as? Int32 ?? Int32.max) == 0
        }
    }
}
