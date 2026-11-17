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
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let supported = (try? request.supportedRecognitionLanguages()) ?? []
            request.recognitionLanguages = languages(for: interface).filter { supported.isEmpty || supported.contains($0) }
            do {
                try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
                let lines = (request.results ?? [])
                    .sorted { a, b in
                        // Top to bottom, then left to right (Vision uses a bottom-left origin).
                        abs(a.boundingBox.midY - b.boundingBox.midY) > 0.01 ? a.boundingBox.midY > b.boundingBox.midY : a.boundingBox.minX < b.boundingBox.minX
                    }
                    .compactMap { $0.topCandidates(1).first?.string }
                DispatchQueue.main.async { completion(.success(lines)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    /// The first text recognition by a newly built executable takes about 30 s while macOS prepares
    /// the model for it; later runs take ~0.3 s. Warm it up quietly at low priority after launch so the
    /// first click on Recognize Text after an update does not stall.
    static func prewarm() {
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3) {
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
