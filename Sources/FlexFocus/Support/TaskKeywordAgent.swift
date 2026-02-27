import Foundation
import NaturalLanguage

struct TaskKeywordAgent {
    static let shared = TaskKeywordAgent()
    static let defaultBlockedWords: [String] = [
        "the", "and", "for", "with", "from", "that", "this", "todo", "task", "focus", "work", "today", "then", "have",
        "一个", "一些", "我们", "你们", "他们", "然后", "进行", "完成", "处理", "开始", "继续", "相关", "任务", "专注", "工作", "学习"
    ]

    func extractKeywords(from text: String) -> [String] {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }
        let blockedWords = blockedWordsSet()

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = normalized

        var candidates: [String] = []

        tokenizer.enumerateTokens(in: normalized.startIndex..<normalized.endIndex) { range, _ in
            let token = String(normalized[range])
            let cleaned = cleanToken(token)
            if isKeyword(cleaned, blockedWords: blockedWords) {
                candidates.append(cleaned)
            }
            return true
        }

        var seen = Set<String>()
        var unique: [String] = []
        for token in candidates {
            if seen.insert(token).inserted {
                unique.append(token)
            }
        }
        return unique
    }

    private func blockedWordsSet() -> Set<String> {
        Set(AppSettings.shared.blockedWordsList.map { $0.lowercased() })
    }

    private func cleanToken(_ token: String) -> String {
        token
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func isKeyword(_ token: String, blockedWords: Set<String>) -> Bool {
        guard !token.isEmpty else { return false }
        guard !blockedWords.contains(token) else { return false }

        let hasCJK = token.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }

        if hasCJK {
            return token.count >= 2
        }

        let alnum = token.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) }
        return alnum && token.count >= 3
    }
}
