import SwiftUI
import Charts

struct StatsSidebarView: View {
    let sessions: [FocusSession]
    @Binding var selectedRange: StatisticsRange

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("统计范围", selection: $selectedRange) {
                    ForEach(StatisticsRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Label("每日专注时长", systemImage: "chart.bar")
                        .font(.headline)
                    Chart(timeBuckets) { bucket in
                        BarMark(
                            x: .value("时间", bucket.label),
                            y: .value("秒", bucket.totalSeconds)
                        )
                    }
                    .frame(height: 180)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("任务词云", systemImage: "cloud")
                        .font(.headline)

                    if wordStats.isEmpty {
                        Text("暂无任务词汇")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                            ForEach(wordStats.prefix(40)) { stat in
                                Text(stat.word)
                                    .font(.system(size: fontSize(for: stat.frequency), weight: .semibold))
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("词汇专注占比", systemImage: "chart.pie")
                        .font(.headline)

                    if topPieStats.isEmpty {
                        Text("暂无占比数据")
                            .foregroundStyle(.secondary)
                    } else {
                        Chart(topPieStats) { stat in
                            SectorMark(
                                angle: .value("时长", stat.totalSeconds),
                                innerRadius: .ratio(0.5)
                            )
                            .foregroundStyle(by: .value("词", stat.word))
                        }
                        .frame(height: 200)
                    }
                }
            }
            .padding()
        }
    }

    private var timeBuckets: [TimeBucket] {
        StatsCalculator.buckets(for: sessions, range: selectedRange)
    }

    private var wordStats: [WordStat] {
        StatsCalculator.wordStats(from: sessions)
    }

    private var topPieStats: [WordStat] {
        Array(wordStats.prefix(8))
    }

    private func fontSize(for frequency: Int) -> CGFloat {
        let clamped = min(max(frequency, 1), 12)
        return CGFloat(12 + clamped * 2)
    }
}
