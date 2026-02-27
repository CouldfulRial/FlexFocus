import SwiftUI
import Charts

struct StatsSidebarView: View {
    let sessions: [FocusSession]
    @Binding var selectedRange: StatisticsRange
    private let wordCloudSize = CGSize(width: 280, height: 210)
    private let pieSize = CGSize(width: 280, height: 210)

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
                            y: .value("时长", bucket.totalSeconds)
                        )
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let seconds = value.as(Int.self) {
                                    Text(durationUnitText(seconds))
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("任务词云", systemImage: "cloud")
                        .font(.headline)
                    WordCloudCanvasView(stats: wordStats, width: wordCloudSize.width, height: wordCloudSize.height)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("词汇专注占比", systemImage: "chart.pie")
                        .font(.headline)

                    ZStack {
                        Rectangle()
                            .fill(.white)
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
                        }
                    }
                    .frame(width: pieSize.width, height: pieSize.height)
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

    private func durationUnitText(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return String(format: "%.1fh", Double(seconds) / 3600)
        }
        if seconds >= 60 {
            return "\(seconds / 60)m"
        }
        return "\(seconds)s"
    }
}
