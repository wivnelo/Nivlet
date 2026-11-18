import Foundation
import NaturalLanguage

struct TranslationPlan: Equatable {
    struct Segment: Equatable {
        let text: String
        let paragraph: Int
    }

    static let budget = 600
    static let wrappedLineWeight = 40

    let segments: [Segment]
    let truncated: Bool

    static func isWide(_ scalar: Unicode.Scalar) -> Bool {
        let v = scalar.value
        return (0x3040...0x30FF).contains(v) || (0x3400...0x9FFF).contains(v) || (0xAC00...0xD7AF).contains(v)
            || (0xF900...0xFAFF).contains(v) || (0xFF00...0xFFEF).contains(v) || (0x3000...0x303F).contains(v)
    }

    static func weight(_ text: String) -> Int {
        text.unicodeScalars.reduce(0) { $0 + (isWide($1) ? 3 : 1) }
    }

    static func make(_ text: String) -> TranslationPlan {
        var segments: [Segment] = []
        var remaining = budget
        var truncated = false
        for paragraph in paragraphs(text) {
            guard remaining > 0 else { truncated = true; break }
            var body = paragraph
            if weight(body) > remaining {
                body = cut(body, to: remaining)
                truncated = true
            }
            guard !body.isEmpty else { truncated = true; break }
            remaining -= weight(body)
            let index = segments.last.map { $0.paragraph + 1 } ?? 0
            if index == 0 {
                let sentences = sentencesOf(body)
                if sentences.count > 1 {
                    let first = sentences[0]
                    let rest = String(body[first.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    segments.append(Segment(text: String(body[first]).trimmingCharacters(in: .whitespacesAndNewlines), paragraph: 0))
                    if !rest.isEmpty { segments.append(Segment(text: rest, paragraph: 0)) }
                    if truncated { break }
                    continue
                }
            }
            segments.append(Segment(text: body, paragraph: index))
            if truncated { break }
        }
        return TranslationPlan(segments: segments, truncated: truncated)
    }

    static func paragraphs(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                if !current.isEmpty { result.append(current); current = "" }
                continue
            }
            if current.isEmpty { current = line; continue }
            if continues(current, with: line) {
                current = joinWrapped(current, line)
            } else {
                result.append(current)
                current = line
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    static func continues(_ previous: String, with next: String) -> Bool {
        guard let last = previous.last, weight(previous) >= wrappedLineWeight else { return false }
        if "。！？.!?:：;；…»”\"')）".contains(last) { return false }
        let listPattern = #"^([-•*·–]\s|\d{1,3}[.)、]\s?|[a-zA-Z][.)]\s)"#
        return next.range(of: listPattern, options: .regularExpression) == nil
    }

    static func joinWrapped(_ previous: String, _ next: String) -> String {
        if previous.hasSuffix("-"), let first = next.first, first.isLowercase {
            return String(previous.dropLast()) + next
        }
        let left = previous.unicodeScalars.last.map(isWide) ?? false
        let right = next.unicodeScalars.first.map(isWide) ?? false
        return previous + (left || right ? "" : " ") + next
    }

    static func sentencesOf(_ text: String) -> [Range<String.Index>] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex)
    }

    static func cut(_ text: String, to limit: Int) -> String {
        var kept = text.startIndex
        var used = 0
        for range in sentencesOf(text) {
            let sentenceWeight = weight(String(text[range]))
            if used + sentenceWeight > limit { break }
            used += sentenceWeight
            kept = range.upperBound
        }
        if kept > text.startIndex { return String(text[..<kept]).trimmingCharacters(in: .whitespacesAndNewlines) }
        var end = text.startIndex
        used = 0
        for index in text.indices {
            let w = weight(String(text[index]))
            if used + w > limit { break }
            used += w
            end = text.index(after: index)
        }
        let head = String(text[..<end])
        if let space = head.lastIndex(where: { $0 == " " }), head.distance(from: head.startIndex, to: space) > head.count / 2 {
            return String(head[..<space])
        }
        return head
    }

    func join(_ parts: [String?], target: String) -> String {
        let wide = ["zh", "ja", "ko"].contains(String(target.split(separator: "-").first ?? ""))
        var lines: [String] = []
        var paragraph = -1
        for (segment, part) in zip(segments, parts) {
            guard let part else { break }
            let text = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if segment.paragraph == paragraph, let last = lines.popLast() {
                lines.append(last + (wide ? "" : " ") + text)
            } else {
                lines.append(text)
                paragraph = segment.paragraph
            }
        }
        return lines.joined(separator: "\n")
    }
}
