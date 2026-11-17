// Nivlet capture helper. Started by Toolkit/modules/capture.lua while the capture module is enabled.
// Protocol: one JSON object per line on stdin (commands) and stdout (events). Nothing is written to
// disk except files the user saves; frozen images are released when the overlay closes.
import AppKit

setvbuf(stdout, nil, _IOLBF, 0)

// `capture-helper --permission` answers with the system's own Screen Recording check and exits.
// Nivlet starts this helper, so the answer reflects Nivlet's permission.
if CommandLine.arguments.contains("--prewarm") {
    Recognition.prewarmNow()
    exit(0)
}
if CommandLine.arguments.contains("--permission") {
    print(CGPreflightScreenCaptureAccess() ? "granted" : "denied")
    exit(0)
}

func emit(_ event: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: event), let line = String(data: data, encoding: .utf8) else { return }
    print(line)
}

@MainActor
final class Helper {
    let capturer = Capturer()
    var config = SessionConfig()
    var session: Session?
    var busy = false
    var selfTestPath: String?
    var clickTest = false

    func handle(_ command: [String: Any]) {
        switch command["cmd"] as? String {
        case "config":
            if let v = command["saveDirectory"] as? String { config.saveDirectory = v; PinManager.shared.saveDirectory = v }
            if let v = command["format"] as? String { config.format = v; PinManager.shared.format = v }
            if let v = command["snapWindows"] as? Bool { config.snapWindows = v }
            if let v = command["loupe"] as? Bool { config.loupe = v }
            if let v = command["language"] as? String { config.language = v }
            if let v = command["strings"] as? [String: String] { strings.merge(v) { _, new in new } }
            if let v = command["appearance"] as? String {
                NSApp.appearance = v == "dark" ? NSAppearance(named: .darkAqua) : v == "light" ? NSAppearance(named: .aqua) : nil
            }
        case "capture":
            capture()
        case "pinClipboard":
            PinManager.shared.pinClipboard()
        case "pinFile":
            if let path = command["path"] as? String {
                let w = command["width"] as? Double, h = command["height"] as? Double
                PinManager.shared.pinFile(path, size: w.flatMap { w in h.map { NSSize(width: w, height: $0) } }.flatMap { $0.width > 0 && $0.height > 0 ? $0 : nil })
            }
        #if NIVLET_SELFTEST
        case "selftest":
            selfTestPath = command["path"] as? String
            capture()
        case "selftest-clicks":
            clickTest = true
            capture()
        case "selftest-recognition":
            selfTestRecognition { emit(["event": "selftest-recognition"].merging($0) { a, _ in a }) }
        #endif
        case "quit":
            session?.cancel(); exit(0)
        default:
            emit(["event": "error", "message": "unknown command"])
        }
    }

    func capture() {
        guard !busy, session == nil else { return }
        guard CGPreflightScreenCaptureAccess() else {
            // The system prompt appears once; after the user grants access macOS needs a fresh process,
            // so the helper exits and Lua starts a new one on the next shortcut press.
            let requested = CGRequestScreenCaptureAccess()
            emit(["event": "permission", "granted": requested])
            exit(0)
        }
        busy = true
        let started = DispatchTime.now().uptimeNanoseconds
        Task { @MainActor in
            defer { busy = false }
            do {
                let frozen = try await capturer.captureAll()
                let s = Session(frozen: frozen, config: config)
                s.onEvent = { event in emit(event) }
                s.onFinish = { event in
                    emit(event)
                    self.session = nil
                }
                session = s
                s.show()
                #if NIVLET_SELFTEST
                if let path = selfTestPath { selfTestPath = nil; s.runSelfTest(path: path) }
                if clickTest { clickTest = false; s.testClicks() }
                #endif
                emit(["event": "shown", "ms": Int((DispatchTime.now().uptimeNanoseconds - started) / 1_000_000)])
            } catch {
                capturer.invalidate()
                emit(["event": "error", "message": "capture", "detail": "\(error)"])
            }
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let helper = MainActor.assumeIsolated { Helper() }
MainActor.assumeIsolated { PinManager.shared.emit = { emit($0) } }

NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { _ in
    MainActor.assumeIsolated { helper.capturer.invalidate() }
}

Thread.detachNewThread {
    while let line = readLine() {
        guard let data = line.data(using: .utf8), let command = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
        DispatchQueue.main.async { MainActor.assumeIsolated { helper.handle(command) } }
    }
    // Nivlet closed our stdin: it quit or turned the module off.
    DispatchQueue.main.async { exit(0) }
}

Task { @MainActor in
    if CGPreflightScreenCaptureAccess() { await helper.capturer.prewarm() }
    emit(["event": "ready", "permission": CGPreflightScreenCaptureAccess()])
    Recognition.prewarmInBackground()
}
app.run()
