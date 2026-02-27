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

        let candidates = tokenize(normalized)
            .map(cleanToken)
            .filter { isKeyword($0, blockedWords: blockedWords) }

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

    private func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""

        let scalars = Array(text.unicodeScalars)

        func flush() {
            if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        }

        for index in scalars.indices {
            let scalar = scalars[index]

            if CharacterSet.alphanumerics.contains(scalar) || isCJK(scalar) {
                current.unicodeScalars.append(scalar)
                continue
            }

            if scalar == "-" {
                let hasLeft = !current.isEmpty
                let hasRight = index + 1 < scalars.count && CharacterSet.alphanumerics.contains(scalars[index + 1])
                if hasLeft && hasRight {
                    current.unicodeScalars.append(scalar)
                    continue
                }
            }

            flush()
        }

        flush()
        return tokens
    }

    private func isCJK(_ scalar: UnicodeScalar) -> Bool {
        (0x4E00...0x9FFF).contains(Int(scalar.value))
    }

    private func isKeyword(_ token: String, blockedWords: Set<String>) -> Bool {
        guard !token.isEmpty else { return false }
        guard !blockedWords.contains(token) else { return false }

        let hasCJK = token.unicodeScalars.contains { scalar in
            isCJK(scalar)
        }

        if hasCJK {
            return token.count >= 2
        }

        let asciiWord = token.unicodeScalars.allSatisfy { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "-"
        }
        return asciiWord && token.count >= 3
    }
}
