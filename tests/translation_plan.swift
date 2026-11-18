import Foundation

func check(_ condition: Bool, _ message: String) {
    if !condition { print("FAIL: " + message); exit(1) }
}

let short = TranslationPlan.make("Hello world")
check(short.segments == [.init(text: "Hello world", paragraph: 0)] && !short.truncated, "short text is one segment")

let three = TranslationPlan.make("The cat sat on the mat. It was warm. Then it slept.")
check(three.segments.count == 2, "first sentence is split from the rest")
check(three.segments[0].text == "The cat sat on the mat." && three.segments[1].text == "It was warm. Then it slept.", "split keeps order")
check(three.join(["A.", "B. C."], target: "en") == "A. B. C.", "sentences of one paragraph join with a space")
check(three.join(["甲。", "乙。"], target: "zh-Hans") == "甲。乙。", "Chinese output joins without a space")
check(three.join(["A.", nil], target: "en") == "A.", "partial results show the finished prefix")

let wrapped = TranslationPlan.paragraphs("Screen text recognition often returns a sentence that is broken\nacross several lines when it wraps at the edge\nof the window.")
check(wrapped.count == 1 && wrapped[0].contains("broken across several"), "wrapped lines are merged")

let labels = TranslationPlan.paragraphs("File\nEdit\nView")
check(labels == ["File", "Edit", "View"], "short labels stay separate")

let list = TranslationPlan.paragraphs("These are the steps you need to follow before you can start using it\n- open the app\n- choose a file")
check(list.count == 3, "list items are not merged")

let hyphen = TranslationPlan.paragraphs("The system splits words at the end of the line with a hyphen like transla-\ntion here")
check(hyphen.count == 1 && hyphen[0].contains("translation here"), "hyphenated words are rejoined")

let cjk = TranslationPlan.paragraphs("这是一段比较长的中文文字，识别的时候会在窗口边缘被折成两行，后面还\n有一部分内容")
check(cjk.count == 1 && cjk[0].contains("后面还有一部分"), "Chinese wrapped lines join without a space")

let longEnglish = String(repeating: "This sentence is part of a long article. ", count: 120)
let cappedEnglish = TranslationPlan.make(longEnglish)
let englishWeight = cappedEnglish.segments.reduce(0) { $0 + TranslationPlan.weight($1.text) }
check(cappedEnglish.truncated && englishWeight <= TranslationPlan.budget && englishWeight > TranslationPlan.budget / 2, "long English text is cut near the budget")
check(cappedEnglish.segments.last!.text.hasSuffix("."), "English text is cut at a sentence end")

let longChinese = String(repeating: "这是一篇很长的文章中的一句话。", count: 60)
let cappedChinese = TranslationPlan.make(longChinese)
let chineseChars = cappedChinese.segments.reduce(0) { $0 + $1.text.count }
check(cappedChinese.truncated && chineseChars <= TranslationPlan.budget / 3, "Chinese characters count three times")

let manyParagraphs = (1...80).map { "Item number \($0) in a list" }.joined(separator: "\n\n")
let cappedParagraphs = TranslationPlan.make(manyParagraphs)
check(cappedParagraphs.truncated && cappedParagraphs.segments.count < 80, "many paragraphs are capped")
check(cappedParagraphs.segments.map(\.paragraph) == Array(0..<cappedParagraphs.segments.count), "paragraph indices stay in order")

let noBreak = String(repeating: "a", count: 2000)
let cappedWord = TranslationPlan.make(noBreak)
check(cappedWord.truncated && cappedWord.segments.count == 1 && cappedWord.segments[0].text.count == TranslationPlan.budget, "text without breaks is cut at the budget")

check(TranslationPlan.make("  \n \n").segments.isEmpty, "blank text has no segments")

print("Translation plan: budget, line merging, list and label separation, first-sentence split and joining passed")
