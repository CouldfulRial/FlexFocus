import SwiftUI
import AppKit

private struct PlacedWord: Identifiable {
    let id = UUID()
    let stat: WordStat
    let rect: CGRect
    let isVertical: Bool
    let color: Color
    let fontSize: CGFloat
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x123456789ABCDEF : seed
    }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

struct WordCloudCanvasView: View {
    let stats: [WordStat]
    let width: CGFloat
    let height: CGFloat

    private let colors: [Color] = [.red, .orange, .blue, .purple, .pink, .teal, .indigo, .mint]

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)

            ForEach(layoutWords(in: CGSize(width: width, height: height))) { item in
                Text(item.stat.word)
                    .font(.system(size: item.fontSize, weight: .semibold))
                    .foregroundStyle(item.color)
                    .fixedSize()
                    .rotationEffect(item.isVertical ? .degrees(90) : .degrees(0))
                    .position(x: item.rect.midX, y: item.rect.midY)
            }

            if stats.isEmpty {
                Text("暂无任务词汇")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .accessibilityElement(children: .contain)
    }

    private func layoutWords(in size: CGSize) -> [PlacedWord] {
        guard size.width > 0, size.height > 0 else { return [] }

        let limited = Array(stats.prefix(45))
        guard !limited.isEmpty else { return [] }

        let maxFrequency = max(1, limited.map(\.frequency).max() ?? 1)
        let minFont: CGFloat = 13
        let maxFont: CGFloat = 40

        let seedBase = limited.reduce(UInt64(0)) { partial, item in
            partial &+ UInt64(item.word.hashValue.magnitude)
        }
        var rng = SeededGenerator(seed: seedBase)

        var placed: [PlacedWord] = []
        var occupied: [CGRect] = []

        for (idx, stat) in limited.enumerated() {
            let ratio = CGFloat(stat.frequency) / CGFloat(maxFrequency)
            var fontSize = minFont + (maxFont - minFont) * ratio
            let color = colors[idx % colors.count]
            var placedWord: PlacedWord?

            for attempt in 0..<450 {
                let preferVertical = idx > 4 && (attempt % 7 == 0)
                let isVertical = preferVertical && Double.random(in: 0...1, using: &rng) < 0.2

                let measured = measureWord(stat.word, fontSize: fontSize)
                let wordSize = isVertical
                    ? CGSize(width: measured.height, height: measured.width)
                    : measured

                let margin: CGFloat = 4
                let maxX = max(margin + wordSize.width / 2, size.width - margin - wordSize.width / 2)
                let maxY = max(margin + wordSize.height / 2, size.height - margin - wordSize.height / 2)
                let minX = margin + wordSize.width / 2
                let minY = margin + wordSize.height / 2

                if minX > maxX || minY > maxY {
                    continue
                }

                let x = CGFloat.random(in: minX...maxX, using: &rng)
                let y = CGFloat.random(in: minY...maxY, using: &rng)
                let rect = CGRect(
                    x: x - wordSize.width / 2,
                    y: y - wordSize.height / 2,
                    width: wordSize.width,
                    height: wordSize.height
                ).insetBy(dx: -2, dy: -2)

                if occupied.allSatisfy({ !$0.intersects(rect) }) {
                    let item = PlacedWord(
                        stat: stat,
                        rect: rect.insetBy(dx: 2, dy: 2),
                        isVertical: isVertical,
                        color: color,
                        fontSize: fontSize
                    )
                    placedWord = item
                    occupied.append(rect)
                    break
                }

                if attempt % 70 == 69 {
                    fontSize = max(minFont, fontSize - 2)
                }
            }

            if let placedWord {
                placed.append(placedWord)
            }
        }

        return placed
    }

    private func measureWord(_ word: String, fontSize: CGFloat) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        ]
        let size = (word as NSString).size(withAttributes: attributes)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
}
