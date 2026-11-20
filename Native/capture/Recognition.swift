import AppKit
import Vision

/// On-device text and QR recognition with Vision. Nothing leaves the Mac.
enum Recognition {
    /// The first language picks Vision's model. With English first it uses the Latin model and Chinese
    /// comes back as garbage or not at all, while the CJK models read English just as well. So a CJK
    /// language always leads: Japanese or Traditional Chinese when that is the interface language,
    /// otherwise Simplified Chinese, including for an English interface.
    static func languages(for interface: String) -> [String] {
        let first: String = ["zh-Hant": "zh-Hant", "ja": "ja-JP"][interface] ?? "zh-Hans"
        return [first] + ["zh-Hans", "zh-Hant", "ja-JP", "en-US"].filter { $0 != first }
    }

    /// Accurate mode only: fast mode garbles Chinese and Japanese (S0 measurement).
    static func text(in image: CGImage, interface: String, completion: @escaping (Result<[String], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result: Result<[String], Error>
            do {
                result = .success(try lines(in: image, interface: interface))
            } catch {
                emit(["event": "recognitionError", "detail": String(describing: error)])
                result = linesInFreshProcess(image, interface: interface)
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    static func lines(in image: CGImage, interface: String) throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let supported = (try? request.supportedRecognitionLanguages()) ?? []
        request.recognitionLanguages = languages(for: interface).filter { supported.isEmpty || supported.contains($0) }
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        return (request.results ?? [])
            .sorted { a, b in
                abs(a.boundingBox.midY - b.boundingBox.midY) > 0.01 ? a.boundingBox.midY > b.boundingBox.midY : a.boundingBox.minX < b.boundingBox.minX
            }
            .compactMap { $0.topCandidates(1).first?.string }
    }

    enum FreshProcessError: Error { case unavailable, failed(Int32) }

    static func linesInFreshProcess(_ image: CGImage, interface: String) -> Result<[String], Error> {
        guard let exe = Bundle.main.executableURL, let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            return .failure(FreshProcessError.unavailable)
        }
        let child = Process()
        child.executableURL = exe
        child.arguments = ["--recognize", interface]
        let input = Pipe(), output = Pipe()
        child.standardInput = input; child.standardOutput = output; child.standardError = FileHandle.nullDevice
        do { try child.run() } catch { return .failure(error) }
        DispatchQueue.global(qos: .userInitiated).async {
            input.fileHandleForWriting.write(png)
            try? input.fileHandleForWriting.close()
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        child.waitUntilExit()
        guard child.terminationStatus == 0, let lines = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            emit(["event": "recognitionError", "detail": "fresh process exited with \(child.terminationStatus)"])
            return .failure(FreshProcessError.failed(child.terminationStatus))
        }
        return .success(lines)
    }

    static func recognizeStandardInput(interface: String) -> Int32 {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let lines = try? lines(in: image, interface: interface),
              let json = try? JSONSerialization.data(withJSONObject: lines) else { return 1 }
        FileHandle.standardOutput.write(json)
        return 0
    }

    /// The first text recognition by a newly built executable takes about 30 s while macOS prepares
    /// the model for it; later runs take ~0.3 s. Loading the model also keeps ~40 MB resident, so the
    /// warm-up runs once per helper version in a short-lived child process (`--prewarm`) that exits
    /// afterwards, leaving the resident helper small.
    static func prewarmInBackground() {
        guard let exe = Bundle.main.executableURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: exe.path),
              let size = attrs[.size] as? NSNumber, let date = attrs[.modificationDate] as? Date,
              let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let dir = caches.appendingPathComponent("dev.local.DesktopToolkit", isDirectory: true)
        let marker = dir.appendingPathComponent("capture-ocr-ready-\(size.intValue)-\(Int(date.timeIntervalSince1970))")
        if FileManager.default.fileExists(atPath: marker.path) { return }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3) {
            let child = Process()
            child.executableURL = exe
            child.arguments = ["--prewarm"]
            child.qualityOfService = .utility
            child.standardInput = FileHandle.nullDevice; child.standardOutput = FileHandle.nullDevice; child.standardError = FileHandle.nullDevice
            guard (try? child.run()) != nil else { return }
            child.waitUntilExit()
            guard child.terminationStatus == 0 else { return }
            // Old markers belong to previous versions.
            if let old = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
                for name in old where name.hasPrefix("capture-ocr-ready-") { try? FileManager.default.removeItem(at: dir.appendingPathComponent(name)) }
            }
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: marker.path, contents: Data())
        }
    }

    /// Runs one small recognition so macOS prepares the model for this executable.
    static func prewarmNow() {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 160, pixelsHigh: 48, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        guard let rep, let context = NSGraphicsContext(bitmapImageRep: rep) else { return }
        NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
        NSColor.white.setFill(); NSRect(x: 0, y: 0, width: 160, height: 48).fill()
        ("Nivlet 截图" as NSString).draw(at: NSPoint(x: 8, y: 12), withAttributes: [.font: NSFont.systemFont(ofSize: 20), .foregroundColor: NSColor.black])
        NSGraphicsContext.restoreGraphicsState()
        guard let image = rep.cgImage else { return }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = languages(for: "zh-Hans")
        try? VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
    }

    struct Code { let payload: String; let box: CGRect }

    /// QR codes with their normalised bounding boxes (bottom-left origin, 0–1).
    static func codes(in image: CGImage, completion: @escaping (Result<[Code], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNDetectBarcodesRequest()
            request.symbologies = [.qr]
            do {
                try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
                var seen = Set<String>()
                let codes = (request.results ?? []).compactMap { r -> Code? in
                    guard let p = r.payloadStringValue, !p.isEmpty, seen.insert(p).inserted else { return nil }
                    return Code(payload: p, box: r.boundingBox)
                }
                DispatchQueue.main.async { completion(.success(codes)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    /// Only plain web links get an Open button.
    static func webURL(_ payload: String) -> URL? {
        guard let url = URL(string: payload.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https", url.host != nil else { return nil }
        return url
    }
}
