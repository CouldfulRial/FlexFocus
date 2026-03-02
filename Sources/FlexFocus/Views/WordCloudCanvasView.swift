import SwiftUI
import AppKit

private struct PlacedWord: Identifiable {
    let id: String
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var cachedWords: [PlacedWord] = []
    @State private var cachedStatsSignature = ""
    @State private var cachedSizeBucket = ""
    @State private var cachedThemeSignature = ""

    private var colors: [Color] {
        [
            ThemePalette.color(lightHex: "#8B9BA8", scheme: colorScheme),
            ThemePalette.color(lightHex: "#9C8FA3", scheme: colorScheme),
            ThemePalette.color(lightHex: "#7E9A91", scheme: colorScheme),
            ThemePalette.color(lightHex: "#A19384", scheme: colorScheme),
            ThemePalette.color(lightHex: "#8793B0", scheme: colorScheme),
            ThemePalette.color(lightHex: "#8DA18B", scheme: colorScheme),
            ThemePalette.color(lightHex: "#9E9A86", scheme: colorScheme),
            ThemePalette.color(lightHex: "#8F8F9E", scheme: colorScheme)
        ]
    }

    var body: some View {
        ZStack {
            Color.clear

            ForEach(cachedWords) { item in
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
        .onAppear {
            updateLayoutIfNeeded(forceDataRefresh: true)
        }
        .onChange(of: statsSignature) { _, _ in
            updateLayoutIfNeeded(forceDataRefresh: true)
        }
        .onChange(of: sizeBucketSignature) { _, _ in
            updateLayoutIfNeeded(forceDataRefresh: false)
        }
        .onChange(of: themeSignature) { _, _ in
            updateLayoutIfNeeded(forceDataRefresh: true)
        }
    }

    private var statsSignature: String {
        stats
            .sorted { $0.word.localizedCompare($1.word) == .orderedAscending }
            .map { "\($0.word)|\($0.frequency)|\(Int($0.totalSeconds.rounded()))" }
            .joined(separator: ";")
    }

    private var sizeBucketSignature: String {
        let widthBucket = Int((max(1, width) / 24).rounded(.down))
        let heightBucket = Int((max(1, height) / 24).rounded(.down))
        return "\(widthBucket)x\(heightBucket)"
    }

    private var themeSignature: String {
        let scheme = colorScheme == .dark ? "dark" : "light"
        let inverted = AppSettings.shared.invertThemeColorsInDarkMode ? "inv" : "keep"
        return "\(scheme)-\(inverted)"
    }

    private func updateLayoutIfNeeded(forceDataRefresh: Bool) {
        let dataChanged = cachedStatsSignature != statsSignature || cachedThemeSignature != themeSignature
        let sizeBucketChanged = cachedSizeBucket != sizeBucketSignature
        guard dataChanged || (sizeBucketChanged && !forceDataRefresh) || forceDataRefresh else { return }

        cachedStatsSignature = statsSignature
        cachedSizeBucket = sizeBucketSignature
        cachedThemeSignature = themeSignature
        cachedWords = layoutWords(in: CGSize(width: width, height: height))
    }

    private func layoutWords(in size: CGSize) -> [PlacedWord] {
        guard size.width > 0, size.height > 0 else { return [] }

        let limited = Array(stats.prefix(45))
        guard !limited.isEmpty else { return [] }

        let maxFrequency = max(1, limited.map(\.frequency).max() ?? 1)
        let (minFont, maxFont) = adaptiveFontBounds(for: size, stats: limited)
        let allowVerticalWords = size.width >= 280 && size.height >= 180

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
                let isVertical = allowVerticalWords && preferVertical && Double.random(in: 0...1, using: &rng) < 0.2

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
                        id: stat.id,
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

    private func adaptiveFontBounds(for size: CGSize, stats: [WordStat]) -> (min: CGFloat, max: CGFloat) {
        let baseMin: CGFloat = 13
        let baseMax: CGFloat = 40

        let baselineArea: CGFloat = 340 * 260
        let currentArea = max(1, size.width * size.height)
        let areaScale = sqrt(currentArea / baselineArea).clamped(to: 0.55...1.2)

        let longestWord = stats.max(by: { $0.word.count < $1.word.count })?.word ?? ""
        let longestAtBase = max(1, measureWord(longestWord, fontSize: baseMax).width)
        let maxAllowedWidth = max(1, size.width * 0.86)
        let widthScale = (maxAllowedWidth / longestAtBase).clamped(to: 0.45...1.0)

        let heightScale = (size.height / 240).clamped(to: 0.55...1.1)
        let scale = min(areaScale, widthScale, heightScale)

        let scaledMax = max(12, baseMax * scale)
        let scaledMin = max(9, min(baseMin * scale, scaledMax - 2))
        return (scaledMin, scaledMax)
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
