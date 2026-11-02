

import Foundation
import CoreGraphics
import ImageIO
import CoreText

struct Manifest: Decodable {
    let width: Int
    let height: Int
    let fps: Double
    let frames: Int
    let seconds: Double
    let languages: [String]
    let durationsMs: [Double]
}

struct MediaFailure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw MediaFailure(message) }
}

func source(_ url: URL) throws -> CGImageSource {
    guard let result = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        throw MediaFailure("Cannot decode \(url.path)")
    }
    return result
}

func decoded(_ source: CGImageSource, _ index: Int) throws -> CGImage {
    guard let result = CGImageSourceCreateImageAtIndex(source, index, nil) else {
        throw MediaFailure("Cannot decode frame \(index)")
    }
    return result
}

func writeContactSheet(_ gif: CGImageSource, _ manifest: Manifest, _ url: URL) throws -> [Int] {
    let columns = 4, rows = 3, thumbWidth = 280
    let thumbHeight = Int((Double(thumbWidth) * Double(manifest.height) / Double(manifest.width)).rounded())
    let labelHeight = 22
    let evenlySpaced = (0..<(columns * rows)).map {
        Int((Double($0) * Double(manifest.frames - 1) / Double(columns * rows - 1)).rounded())
    }
    let indices = manifest.frames == 224
        ? [0, 20, 40, 60, 70, 82, 100, 135, 180, 195, 198, 215] : evenlySpaced
    guard let context = CGContext(data: nil, width: thumbWidth * columns,
        height: (thumbHeight + labelHeight) * rows, bitsPerComponent: 8,
        bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        throw MediaFailure("Cannot allocate contact sheet")
    }
    context.setFillColor(CGColor(gray: 0.08, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
    context.interpolationQuality = .high
    for (position, index) in indices.enumerated() {
        let x = (position % columns) * thumbWidth
        let y = context.height - ((position / columns) + 1) * (thumbHeight + labelHeight)
        context.draw(try decoded(gif, index), in: CGRect(x: x, y: y + labelHeight,
            width: thumbWidth, height: thumbHeight))
        let label = "Frame \(index) · \(String(format: "%.2f", manifest.durationsMs.prefix(index).reduce(0, +) / 1000)) s"
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Menlo" as CFString, 11, nil),
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0.9, alpha: 1)
        ]
        context.textPosition = CGPoint(x: x + 7, y: y + 6)
        CTLineDraw(CTLineCreateWithAttributedString(NSAttributedString(string: label, attributes: attributes)), context)
    }
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        throw MediaFailure("Cannot create contact sheet")
    }
    CGImageDestinationAddImage(destination, image, nil)
    try require(CGImageDestinationFinalize(destination), "Cannot finish contact sheet")
    return indices
}

do {
    try require(CommandLine.arguments.count == 2, "Usage: encode-readme-demo.swift <repository>")
    let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    let captures = root.appendingPathComponent("build/readme-demo", isDirectory: true)
    let output = root.appendingPathComponent("build/media-final", isDirectory: true)
    let manifestData = try Data(contentsOf: captures.appendingPathComponent("manifest.json"))
    let manifest = try JSONDecoder().decode(Manifest.self, from: manifestData)
    try require(manifest.width > 0 && manifest.height > 0 && manifest.frames > 1, "Invalid dimensions or frame count")
    try require(manifest.fps > 0 && manifest.fps.isFinite && manifest.seconds > 0 && manifest.seconds.isFinite, "Invalid timing")
    try require(manifest.languages == ["en", "zh"], "Expected exactly the en and zh media captures")
    try require(manifest.durationsMs.count == manifest.frames, "One duration is required per frame")
    try require(manifest.durationsMs.allSatisfy { $0.isFinite && $0 >= 20 }, "GIF durations must be finite and at least 20 ms")
    try require(abs(manifest.durationsMs.reduce(0, +) - manifest.seconds * 1000) < 0.01, "Requested durations do not match total seconds")
    try require(abs(Double(manifest.frames) / manifest.fps - manifest.seconds) < 0.01, "Frame rate and total seconds disagree")


    var elapsedMs = 0.0, previousCentiseconds = 0
    let delays: [Int] = manifest.durationsMs.map { duration in
        elapsedMs += duration
        let end = Int((elapsedMs / 10).rounded())
        defer { previousCentiseconds = end }
        return end - previousCentiseconds
    }
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    var results: [[String: Any]] = []
    for language in manifest.languages {
        let input = captures.appendingPathComponent(language, isDirectory: true)
        let expectedNames = (0..<manifest.frames).map { String(format: "%04d.png", $0) }
        let actualNames = try FileManager.default.contentsOfDirectory(atPath: input.path)
            .filter { $0.lowercased().hasSuffix(".png") }.sorted()
        try require(actualNames == expectedNames, "\(language): capture filenames do not exactly match the manifest")
        let target = output.appendingPathComponent("overview-\(language).gif")
        guard let destination = CGImageDestinationCreateWithURL(target as CFURL,
            "com.compuserve.gif" as CFString, manifest.frames, nil) else {
            throw MediaFailure("Cannot create \(target.path)")
        }
        CGImageDestinationSetProperties(destination, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
        ] as CFDictionary)
        for (index, name) in expectedNames.enumerated() {
            try autoreleasepool {
                let image = try decoded(source(input.appendingPathComponent(name)), 0)
                try require(image.width == manifest.width && image.height == manifest.height,
                    "\(language) frame \(index): unexpected dimensions")
                let seconds = Double(delays[index]) / 100
                CGImageDestinationAddImage(destination, image, [
                    kCGImagePropertyGIFDictionary: [
                        kCGImagePropertyGIFDelayTime: seconds,
                        kCGImagePropertyGIFUnclampedDelayTime: seconds
                    ]
                ] as CFDictionary)
            }
        }
        try require(CGImageDestinationFinalize(destination), "\(language): GIF encoding failed")
        let check = try source(target)
        try require(CGImageSourceGetCount(check) == manifest.frames, "\(language): encoded frame count changed")
        let properties = CGImageSourceCopyProperties(check, nil) as? [CFString: Any]
        let gifProperties = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        try require((gifProperties?[kCGImagePropertyGIFLoopCount] as? NSNumber)?.intValue == 0,
            "\(language): GIF is not an infinite loop")
        var actualDelays: [Int] = []
        for index in 0..<manifest.frames {
            try autoreleasepool {
                let image = try decoded(check, index)
                try require(image.width == manifest.width && image.height == manifest.height,
                    "\(language): encoded frame \(index) has unexpected dimensions")
                let properties = CGImageSourceCopyPropertiesAtIndex(check, index, nil) as? [CFString: Any]
                let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
                guard let seconds = (gif?[kCGImagePropertyGIFUnclampedDelayTime] ?? gif?[kCGImagePropertyGIFDelayTime]) as? NSNumber else {
                    throw MediaFailure("\(language): frame \(index) has no GIF delay")
                }
                actualDelays.append(Int((seconds.doubleValue * 1000).rounded()))
            }
        }
        try require(actualDelays == delays.map { $0 * 10 }, "\(language): encoded timing differs from requested centisecond timing")
        let sheet = output.appendingPathComponent("overview-\(language)-contactsheet.png")
        let indices = try writeContactSheet(check, manifest, sheet)
        let bytes = (try FileManager.default.attributesOfItem(atPath: target.path)[.size] as! NSNumber).intValue
        results.append([
            "language": language, "path": target.path, "width": manifest.width, "height": manifest.height,
            "frames": manifest.frames, "durationMs": actualDelays.reduce(0, +), "delaysMs": actualDelays,
            "loop": 0, "bytes": bytes, "contactSheet": sheet.path, "contactSheetFrames": indices,
            "decoder": "macOS ImageIO; every encoded frame decoded", "status": "passed"
        ])
        print("\(language): \(manifest.frames) frames, \(actualDelays.reduce(0, +)) ms, \(manifest.width)×\(manifest.height), \(bytes) bytes")
    }
    let report: [String: Any] = ["encoder": "macOS ImageIO", "captureManifest": "build/readme-demo/manifest.json",
        "outputs": results, "note": "Sample-data frontend interaction capture; not a native end-to-end recording."]
    try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        .write(to: output.appendingPathComponent("gif-validation.json"), options: .atomic)
} catch {
    fputs("GIF encoding failed: \(error)\n", stderr)
    exit(1)
}
