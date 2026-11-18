import AppKit
import NaturalLanguage
import SwiftUI
import Translation

/// System translation only (on device). macOS 26+ calls an installed language pair directly; macOS
/// 15–25, and any pair whose language pack still needs downloading, go through SwiftUI's translation
/// task hosted in an invisible window, which is also what shows the system download prompt.
/// Nothing is loaded until the first translation, so the idle helper stays small.
enum TranslateError: Error { case unsupported, unavailable, needsSystem }

enum Direction {
    /// Language of the text. Text with Han, kana or Hangul goes by NaturalLanguage; other scripts
    /// are often too short to identify ("OK" reads as Polish), so they count as English unless
    /// the recogniser is confident.
    static func detect(_ text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let top = recognizer.languageHypotheses(withMaximum: 1).first
        let cjk = text.unicodeScalars.contains { (0x3040...0x30FF).contains($0.value) || (0x3400...0x9FFF).contains($0.value) || (0xAC00...0xD7AF).contains($0.value) }
        if cjk, let lang = recognizer.dominantLanguage { return lang.rawValue }
        if let top, top.value >= 0.6 { return top.key.rawValue }
        return "en"
    }

    /// Automatic rule: Chinese → English, everything else → Simplified Chinese; a remembered choice
    /// for this source language wins. A fixed target that equals the source falls back to the rule.
    static func target(source: String, mode: String, remembered: [String: String]) -> String {
        let rule = source.hasPrefix("zh") ? "en" : "zh-Hans"
        if mode == "auto" { return remembered[source] ?? rule }
        return family(mode) == family(source) ? rule : mode
    }

    /// "zh-Hans" and "zh-Hant" are one family here: translating between them is not offered.
    static func family(_ code: String) -> String { String(code.split(separator: "-").first ?? Substring(code)) }
}

/// Targets offered in the window's language menu, shown with their names in the interface language.
let translationTargets = ["zh-Hans", "zh-Hant", "en", "ja", "ko", "fr", "de", "es", "it", "pt", "ru", "th", "vi", "ar"]

func languageName(_ code: String, interface: String) -> String {
    let locale = Locale(identifier: interface == "zh-Hant" ? "zh-Hant" : interface == "ja" ? "ja" : interface == "en" ? "en" : "zh-Hans")
    return locale.localizedString(forIdentifier: code) ?? code
}

@available(macOS 15.0, *)
@MainActor
final class SystemTranslator {
    static let shared = SystemTranslator()
    static let warmWindow: TimeInterval = 50
    static let warmInterval: UInt64 = 4_000_000_000
    private var host: NSPanel?
    private let model = HostModel()
    private var sessions: [String: AnyObject] = [:]
    private var installedPairs: Set<String> = []
    private var active = 0
    private var warmTask: Task<Void, Never>?

    func translate(_ texts: [String], from source: String, to target: String, onSegment: @escaping (Int, String) -> Void) async throws {
        let from = Locale.Language(identifier: source), to = Locale.Language(identifier: target)
        let key = "\(source)>\(target)"
        warmTask?.cancel()
        active += 1
        defer {
            active -= 1
            if active == 0 { keepWarm(key) }
        }
        do {
            if try await isInstalled(from, to, key: key), #available(macOS 26.0, *) {
                let session = (sessions[key] as? TranslationSession) ?? TranslationSession(installedSource: from, target: to)
                sessions[key] = session
                let requests = texts.enumerated().map { TranslationSession.Request(sourceText: $0.element, clientIdentifier: String($0.offset)) }
                for try await response in session.translate(batch: requests) {
                    if let id = response.clientIdentifier, let index = Int(id) { onSegment(index, response.targetText) }
                }
                return
            }
            for (index, text) in texts.enumerated() {
                onSegment(index, try await viaSwiftUI(text, from: from, to: to))
            }
        } catch {
            installedPairs.remove(key)
            sessions[key] = nil
            throw error
        }
    }

    private func isInstalled(_ from: Locale.Language, _ to: Locale.Language, key: String) async throws -> Bool {
        if installedPairs.contains(key) { return true }
        let status = await LanguageAvailability().status(from: from, to: to)
        if status == .unsupported { throw TranslateError.unsupported }
        if status == .installed { installedPairs.insert(key); return true }
        return false
    }

    private func keepWarm(_ key: String) {
        guard #available(macOS 26.0, *), sessions[key] != nil else { return }
        warmTask?.cancel()
        warmTask = Task { @MainActor [weak self] in
            let end = Date().addingTimeInterval(SystemTranslator.warmWindow)
            while Date() < end {
                try? await Task.sleep(nanoseconds: SystemTranslator.warmInterval)
                guard !Task.isCancelled, let self, self.active == 0 else { return }
                guard let session = self.sessions[key] as? TranslationSession else { return }
                _ = try? await session.translate("a")
            }
        }
    }

    private func viaSwiftUI(_ text: String, from: Locale.Language, to: Locale.Language) async throws -> String {
        if host == nil {
            let panel = NSPanel(contentRect: NSRect(x: -10000, y: -10000, width: 1, height: 1), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.alphaValue = 0
            panel.ignoresMouseEvents = true
            panel.contentView = NSHostingView(rootView: TranslationHost(model: model))
            panel.orderFrontRegardless()
            host = panel
        }
        return try await withCheckedThrowingContinuation { continuation in
            model.request(text: text, from: from, to: to, continuation: continuation)
        }
    }
}

@available(macOS 15.0, *)
@MainActor
final class HostModel: ObservableObject {
    @Published var configuration: TranslationSession.Configuration?
    var text = ""
    var continuation: CheckedContinuation<String, Error>?

    func request(text: String, from: Locale.Language, to: Locale.Language, continuation: CheckedContinuation<String, Error>) {
        self.continuation?.resume(throwing: CancellationError())
        self.text = text
        self.continuation = continuation
        // A new configuration value (re)runs the translation task.
        configuration = .init(source: from, target: to)
    }

    func finish(_ result: Result<String, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

@available(macOS 15.0, *)
struct TranslationHost: View {
    @ObservedObject var model: HostModel
    var body: some View {
        Color.clear.frame(width: 1, height: 1)
            .translationTask(model.configuration) { session in
                let text = await MainActor.run { model.text }
                do {
                    let response = try await session.translate(text)
                    await MainActor.run { model.finish(.success(response.targetText)) }
                } catch {
                    await MainActor.run { model.finish(.failure(error)) }
                }
            }
    }
}
