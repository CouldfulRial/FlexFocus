import SwiftUI
import Charts

struct StatsSidebarView: View {
    let sessions: [FocusSession]
    @Binding var selectedRange: StatisticsRange
    @Environment(\.colorScheme) private var colorScheme
    private let sectionSpacing: CGFloat = 12
    private let outerPadding: CGFloat = 12
    private let topControlHeight: CGFloat = 44
    @State private var rangeReferenceDate: Date = .now
    @State private var timelineDate: Date = .now
    @State private var isTimelineCalendarPresented = false
    private let calendar = Calendar.current

    var body: some View {
        GeometryReader { proxy in
            let availableHeight = max(120, proxy.size.height - topControlHeight - (sectionSpacing * 3) - (outerPadding * 2))
            let sectionHeight = max(120, availableHeight / 3)

            VStack(alignment: .leading, spacing: sectionSpacing) {
                HStack(spacing: 10) {
                    Text("横坐标区间")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $selectedRange) {
                        ForEach(StatisticsRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                .frame(height: topControlHeight)

                VStack(alignment: .leading, spacing: 8) {
                    Label("专注时长", systemImage: "chart.bar")
                        .font(.headline)
                    Chart(timeBuckets) { bucket in
                        if shouldHighlightBucketBackground(bucket) {
                            RectangleMark(
                                x: .value("区间", bucket.label),
                                yStart: .value("基线", 0),
                                yEnd: .value("高度", maxChartY)
                            )
                            .foregroundStyle(ThemePalette.breakColor(for: colorScheme).opacity(0.15))
                        }

                        BarMark(
                            x: .value("区间", bucket.label),
                            y: .value("时长", bucket.totalSeconds)
                        )
                        .foregroundStyle(changeColor(for: bucket))
                        .annotation(position: .top) {
                            Text(changeText(for: bucket))
                                .font(.caption2)
                                .foregroundStyle(changeColor(for: bucket))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: max(2, timeBuckets.count))) { _ in
                            AxisGridLine()
                        }
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    HStack(spacing: 8) {
                        ZStack {
                            Text("-")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)

                            HStack(spacing: 8) {
                                Button {
                                    rangeReferenceDate = StatsCalculator.shiftedReference(
                                        from: rangeReferenceDate,
                                        range: selectedRange,
                                        step: -1,
                                        calendar: calendar
                                    )
                                } label: {
                                    Image(systemName: "chevron.left")
                                }
                                .buttonStyle(.bordered)

                                Text(windowStartText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(windowEndText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.head)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                Button {
                                    guard canShiftForward else { return }
                                    rangeReferenceDate = nextReferenceDate
                                } label: {
                                    Image(systemName: "chevron.right")
                                }
                                .buttonStyle(.bordered)
                                .disabled(!canShiftForward)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: sectionHeight)

                VStack(alignment: .leading, spacing: 8) {
                    Label("任务词云", systemImage: "cloud")
                        .font(.headline)
                    WordCloudCanvasView(
                        stats: wordStats,
                        width: max(120, proxy.size.width - (outerPadding * 2)),
                        height: max(120, sectionHeight - 32)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: sectionHeight)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Label("时间轴", systemImage: "calendar")
                            .font(.headline)

                        Spacer(minLength: 8)

                        Button {
                            timelineDate = calendar.date(byAdding: .day, value: -1, to: timelineDate) ?? timelineDate
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            isTimelineCalendarPresented = true
                        } label: {
                            Text(timelineDate.formatted(.dateTime.year().month().day()))
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .popover(isPresented: $isTimelineCalendarPresented, arrowEdge: .top) {
                            VStack(alignment: .center, spacing: 12) {
                                Text("选择日期")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                DatePicker(
                                    "",
                                    selection: $timelineDate,
                                    displayedComponents: [.date]
                                )
                                .labelsHidden()
                                .datePickerStyle(.graphical)

                                HStack {
                                    Spacer()
                                    Button("完成") {
                                        isTimelineCalendarPresented = false
                                    }
                                    .buttonStyle(.borderedProminent)
                                    Spacer()
                                }
                            }
                            .padding(12)
                            .frame(width: 300)
                        }

                        Button {
                            timelineDate = calendar.date(byAdding: .day, value: 1, to: timelineDate) ?? timelineDate
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.bordered)
                    }

                    TodayTimelineChartView(
                        sessions: sessions,
                        selectedDate: timelineDate
                    )
                    .frame(width: max(120, proxy.size.width - (outerPadding * 2)), height: max(120, sectionHeight - 32))
                }
                .frame(maxWidth: .infinity, maxHeight: sectionHeight)
            }
            .padding(outerPadding)
            .onChange(of: selectedRange) { _, _ in
                rangeReferenceDate = .now
            }
        }
    }

    private var timeBuckets: [TimeBucket] {
        StatsCalculator.buckets(for: sessions, range: selectedRange, window: statsWindow, calendar: calendar)
    }

    private var wordStats: [WordStat] {
        StatsCalculator.wordStats(from: sessions, in: statsWindow)
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

    private var maxChartY: Int {
        max(1, Int(Double(timeBuckets.map(\.totalSeconds).max() ?? 0) * 1.1))
    }

    private func changeText(for bucket: TimeBucket) -> String {
        let percent = bucket.changeRatio * 100
        return String(format: "%.0f", abs(percent))
    }

    private func changeColor(for bucket: TimeBucket) -> Color {
        if bucket.changeRatio > 0 {
            return ThemePalette.growthUpColor(for: colorScheme)
        }
        if bucket.changeRatio < 0 {
            return ThemePalette.growthDownColor(for: colorScheme)
        }
        return .secondary
    }

    private func isWorkingHourBucket(_ bucket: TimeBucket) -> Bool {
        let hour = calendar.component(.hour, from: bucket.start)
        return hour >= 9 && hour < 17
    }

    private func isWorkdayBucket(_ bucket: TimeBucket) -> Bool {
        let weekday = calendar.component(.weekday, from: bucket.start)
        return weekday >= 2 && weekday <= 6
    }

    private func shouldHighlightBucketBackground(_ bucket: TimeBucket) -> Bool {
        switch selectedRange {
        case .hour:
            return isWorkingHourBucket(bucket)
        case .day:
            return isWorkdayBucket(bucket)
        case .week, .month:
            return false
        }
    }

    private var statsWindow: StatsWindow {
        StatsCalculator.window(for: selectedRange, reference: rangeReferenceDate, calendar: calendar)
    }

    private var nextReferenceDate: Date {
        StatsCalculator.shiftedReference(
            from: rangeReferenceDate,
            range: selectedRange,
            step: 1,
            calendar: calendar
        )
    }

    private var canShiftForward: Bool {
        let nextWindow = StatsCalculator.window(for: selectedRange, reference: nextReferenceDate, calendar: calendar)
        return nextWindow.end <= maxAllowedEndExclusive
    }

    private var maxAllowedEndExclusive: Date {
        let now = Date()
        switch selectedRange {
        case .hour:
            let currentHourStart = calendar.dateInterval(of: .hour, for: now)?.start ?? now
            return calendar.date(byAdding: .hour, value: 1, to: currentHourStart) ?? currentHourStart
        case .day, .week, .month:
            let todayStart = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
        }
    }

    private func displayWindowEnd(_ endExclusive: Date) -> Date {
        endExclusive.addingTimeInterval(-1)
    }

    private var windowStartText: String {
        switch selectedRange {
        case .hour:
            return statsWindow.start.formatted(.dateTime.year().month().day().hour().minute())
        case .day, .week, .month:
            return statsWindow.start.formatted(.dateTime.year().month().day())
        }
    }

    private var windowEndText: String {
        let end = displayWindowEnd(statsWindow.end)
        switch selectedRange {
        case .hour:
            return end.formatted(.dateTime.year().month().day().hour().minute())
        case .day, .week, .month:
            return end.formatted(.dateTime.year().month().day())
        }
    }
}
