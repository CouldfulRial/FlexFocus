import SwiftUI

struct FocusTimerView: View {
    let phase: TimerPhase
    let elapsedFocusSeconds: Int
    let remainingBreakSeconds: Int
    let currentTask: String
    let contentMaxWidth: CGFloat
    let onStart: () -> Void
    let onEndFocus: () -> Void
    let onSkipBreak: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(titleText)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(displayTime)
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(timerColor)

            if !currentTask.isEmpty {
                taskText
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: max(220, contentMaxWidth - 40))
                    .padding(.horizontal, 12)
            }

            HStack(spacing: 12) {
                if case .focusing = phase {
                    Button("结束专注", role: .destructive, action: onEndFocus)
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("开始专注", action: onStart)
                        .buttonStyle(.borderedProminent)
                }

                if case .breaking = phase {
                    Button("跳过休息", action: onSkipBreak)
                        .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .frame(maxWidth: contentMaxWidth)
        .padding()
    }

    private var titleText: String {
        switch phase {
        case .idle:
            return "准备开始"
        case .focusing:
            return "正在专注"
        case .awaitingBreakConfirmation:
            return "专注已结束"
        case .breaking:
            return "休息中"
        }
    }

    private var displayTime: String {
        switch phase {
        case .breaking:
            return format(remainingBreakSeconds)
        default:
            return format(elapsedFocusSeconds)
        }
    }

    private func format(_ seconds: Int) -> String {
        let hour = seconds / 3600
        let minute = (seconds % 3600) / 60
        let second = seconds % 60
        return String(format: "%02d:%02d:%02d", hour, minute, second)
    }

    private var timerColor: Color {
        switch phase {
        case .focusing:
            return ThemePalette.focusColor(for: colorScheme)
        case .breaking:
            return ThemePalette.breakColor(for: colorScheme)
        default:
            return .primary
        }
    }

    private var taskText: Text {
        guard case .focusing = phase else {
            return Text("任务：\(currentTask)")
                .foregroundStyle(.secondary)
        }

        let keywords = TaskKeywordAgent.shared.extractKeywords(from: currentTask)
        guard !keywords.isEmpty else {
            return Text("任务：\(currentTask)")
                .foregroundStyle(.secondary)
        }

        return Text("任务：")
            .foregroundStyle(.secondary)
            + highlightedTaskText(currentTask, keywords: keywords)
    }

    private func highlightedTaskText(_ text: String, keywords: [String]) -> Text {
        let ranges = highlightedRanges(in: text, keywords: keywords)
        guard !ranges.isEmpty else {
            return Text(text).foregroundStyle(.secondary)
        }

        var result = Text("")
        var cursor = text.startIndex

        for range in ranges {
            if cursor < range.lowerBound {
                result = result + Text(String(text[cursor..<range.lowerBound])).foregroundStyle(.secondary)
            }
            result = result + Text(String(text[range])).foregroundStyle(.red)
            cursor = range.upperBound
        }

        if cursor < text.endIndex {
            result = result + Text(String(text[cursor...])).foregroundStyle(.secondary)
        }

        return result
    }

    private func highlightedRanges(in text: String, keywords: [String]) -> [Range<String.Index>] {
        var matchedRanges: [Range<String.Index>] = []

        for keyword in keywords
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ !$0.isEmpty })
            .sorted(by: { $0.count > $1.count }) {
            var searchStart = text.startIndex
            while searchStart < text.endIndex,
                  let range = text.range(
                    of: keyword,
                    options: [.caseInsensitive, .diacriticInsensitive],
                    range: searchStart..<text.endIndex,
                    locale: .current
                  ) {
                matchedRanges.append(range)
                searchStart = range.upperBound
            }
        }

        let sortedRanges = matchedRanges.sorted { lhs, rhs in
            if lhs.lowerBound == rhs.lowerBound {
                return text.distance(from: lhs.lowerBound, to: lhs.upperBound)
                    > text.distance(from: rhs.lowerBound, to: rhs.upperBound)
            }
            return lhs.lowerBound < rhs.lowerBound
        }

        var result: [Range<String.Index>] = []
        for range in sortedRanges {
            if let last = result.last, range.lowerBound < last.upperBound {
                continue
            }
            result.append(range)
        }
        return result
    }
}
