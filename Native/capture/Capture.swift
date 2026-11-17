import AppKit
import ScreenCaptureKit
import CoreImage
import CoreMedia

/// A frozen display: the screen it belongs to and its full-resolution pixels.
struct FrozenScreen {
    let screen: NSScreen
    let image: CGImage
    var pixelScale: CGFloat { CGFloat(image.width) / screen.frame.width }
}

/// Captures every display with ScreenCaptureKit. The shareable-content list is cached and refreshed
/// after each capture and on display changes, which keeps a capture near 70 ms (S0 measurement).
@MainActor
final class Capturer {
    private var content: SCShareableContent?

    func prewarm() async {
        content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    func captureAll() async throws -> [FrozenScreen] {
        if content == nil { await prewarm() }
        guard let content else { throw CaptureError.noContent }
        var result: [FrozenScreen] = []
        for screen in NSScreen.screens {
            guard let id = screen.displayID, let display = content.displays.first(where: { $0.displayID == id }) else { continue }
            let config = SCStreamConfiguration()
            config.width = Int(screen.frame.width * screen.backingScaleFactor)
            config.height = Int(screen.frame.height * screen.backingScaleFactor)
            config.showsCursor = false
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let image: CGImage
            if #available(macOS 14.0, *) {
                config.captureResolution = .best
                image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            } else {
                image = try await SingleFrame.capture(filter: filter, config: config)
            }
            result.append(FrozenScreen(screen: screen, image: image))
        }
        if result.isEmpty { throw CaptureError.noContent }
        Task { await self.prewarm() }
        return result
    }

    func invalidate() { content = nil }
}

enum CaptureError: Error { case noContent, noFrame }

/// macOS 13 has no one-shot screenshot API, so start a stream, keep the first complete frame and stop.
final class SingleFrame: NSObject, SCStreamOutput, @unchecked Sendable {
    // Frames and the start callback arrive on different queues; the lock makes resume happen once.
    private let lock = NSLock()
    private var continuation: CheckedContinuation<CGImage, Error>?
    private var stream: SCStream?
    private let queue = DispatchQueue(label: "nivlet.capture.frame")

    static func capture(filter: SCContentFilter, config: SCStreamConfiguration) async throws -> CGImage {
        let grabber = SingleFrame()
        config.queueDepth = 3
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        return try await withCheckedThrowingContinuation { continuation in
            grabber.continuation = continuation
            let stream = SCStream(filter: filter, configuration: config, delegate: nil)
            grabber.stream = stream
            do {
                try stream.addStreamOutput(grabber, type: .screen, sampleHandlerQueue: grabber.queue)
                stream.startCapture { error in if let error { grabber.resume(.failure(error)) } }
            } catch { grabber.resume(.failure(error)) }
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer buffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen,
              let attachments = CMSampleBufferGetSampleAttachmentsArray(buffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let raw = attachments.first?[.status] as? Int, SCFrameStatus(rawValue: raw) == .complete,
              let pixels = CMSampleBufferGetImageBuffer(buffer) else { return }
        let ci = CIImage(cvPixelBuffer: pixels)
        guard let image = CIContext().createCGImage(ci, from: ci.extent) else { resume(.failure(CaptureError.noFrame)); return }
        resume(.success(image))
    }

    private func resume(_ result: Result<CGImage, Error>) {
        lock.lock()
        let c = continuation, s = stream
        continuation = nil; stream = nil
        lock.unlock()
        guard let c else { return }
        s?.stopCapture { _ in }
        c.resume(with: result)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? { deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID }
}

/// Visible application windows in Cocoa global coordinates, front to back, for hover snapping.
func visibleWindowFrames(excludingPID pid: pid_t) -> [CGRect] {
    guard let primary = NSScreen.screens.first else { return [] }
    let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    return info.compactMap { entry in
        guard (entry[kCGWindowLayer as String] as? Int) == 0,
              (entry[kCGWindowOwnerPID as String] as? pid_t) != pid,
              (entry[kCGWindowAlpha as String] as? Double ?? 1) > 0.01,
              let bounds = entry[kCGWindowBounds as String] as? [String: CGFloat],
              let x = bounds["X"], let y = bounds["Y"], let w = bounds["Width"], let h = bounds["Height"],
              w > 40, h > 40 else { return nil }
        return CGRect(x: x, y: primary.frame.height - y - h, width: w, height: h)
    }
}
