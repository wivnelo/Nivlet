import AppKit
import UniformTypeIdentifiers

/// Pasteboard type that tells Nivlet's clipboard history the image came from a capture.
let captureMarker = NSPasteboard.PasteboardType("dev.nivlet.capture")

enum ClipboardWriter {
    /// Keeps the image alive so TIFF can be produced lazily if a pasting app asks for it.
    private static var provider: TIFFProvider?

    /// `scale` is pixels per point; it is stored as the PNG's DPI so other apps (and pins) show the
    /// screenshot at its on-screen size.
    static func write(_ image: CGImage, scale: CGFloat = 1) -> Bool {
        let rep = NSBitmapImageRep(cgImage: image)
        rep.size = NSSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
        guard let png = rep.representation(using: .png, properties: [:]) else { return false }
        let item = NSPasteboardItem()
        item.setData(png, forType: .png)
        item.setData(Data(), forType: captureMarker)
        let p = TIFFProvider(rep: rep)
        item.setDataProvider(p, forTypes: [.tiff])
        provider = p
        let board = NSPasteboard.general
        board.clearContents()
        return board.writeObjects([item])
    }
}

final class TIFFProvider: NSObject, NSPasteboardItemDataProvider {
    let rep: NSBitmapImageRep
    init(rep: NSBitmapImageRep) { self.rep = rep }
    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        if type == .tiff, let data = rep.tiffRepresentation { item.setData(data, forType: .tiff) }
    }
}

enum FileSaver {
    static func save(_ image: CGImage, directory: String, format: String, scale: CGFloat = 1) throws -> URL {
        let dir = URL(fileURLWithPath: (directory as NSString).expandingTildeInPath, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let ext = format == "jpg" ? "jpg" : "png"
        let base = "Nivlet \(formatter.string(from: Date()))"
        var url = dir.appendingPathComponent("\(base).\(ext)")
        var n = 2
        while FileManager.default.fileExists(atPath: url.path) { url = dir.appendingPathComponent("\(base) \(n).\(ext)"); n += 1 }
        let rep = NSBitmapImageRep(cgImage: image)
        rep.size = NSSize(width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale)
        let data = ext == "jpg" ? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) : rep.representation(using: .png, properties: [:])
        guard let data else { throw CocoaError(.fileWriteUnknown) }
        try data.write(to: url, options: .withoutOverwriting)
        return url
    }
}
