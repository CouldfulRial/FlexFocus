import SwiftUI
import Charts

struct StatsSidebarView: View {
    let sessions: [FocusSession]
    @Binding var selectedRange: StatisticsRange

    @Environment(\.colorScheme) private var colorScheme
    @State private var rangeReferenceDate: Date = .now
    @State private var timelineDate: Date = .now
    @State private var hoveredTimelineWindow: StatsWindow?
    @State private var isDayCalendarPresented = false
    @State private var isWeekCalendarPresented = false

    private let sectionSpacing: CGFloat = 12
    private let outerPadding: CGFloat = 12
    private let topControlHeight: CGFloat = 44
    private let calendar = Calendar.current

    private var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar
    }

    var body: some View {
        GeometryReader { proxy in
            let availableHeight = max(
                120,
                proxy.size.height - topControlHeight - (sectionSpacing * 3) - (outerPadding * 2)
            )
            let sectionHeight = max(120, availableHeight / 3)

            VStack(alignment: .leading, spacing: sectionSpacing) {
                HStack(spacing: 10) {
                    Text("Chart Interval")
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

                focusDurationSection(height: sectionHeight)
                categoryDistributionSection(height: sectionHeight)
                timelineSection(width: proxy.size.width - (outerPadding * 2), height: sectionHeight)
            }
            .padding(outerPadding)
            .onChange(of: selectedRange) { _, _ in
                rangeReferenceDate = .now
                hoveredTimelineWindow = nil
            }
        }
    }

    private func focusDurationSection(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Focus Duration", systemImage: "chart.bar")
                .font(.headline)

            Chart(timeBuckets) { bucket in
                if shouldHighlightBucketBackground(bucket) {
                    RectangleMark(
                        x: .value("Interval", bucket.label),
                        yStart: .value("Baseline", 0),
                        yEnd: .value("Height", maxChartY)
                    )
                    .foregroundStyle(ThemePalette.breakColor(for: colorScheme).opacity(0.15))
                }

                BarMark(
                    x: .value("Interval", bucket.label),
                    y: .value("Duration", bucket.totalSeconds)
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
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(windowEndText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }

    private func categoryDistributionSection(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Category Distribution", systemImage: "chart.pie")
                    .font(.headline)
                Spacer()
                Text(pieWindowLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if pieStats.isEmpty {
                ContentUnavailableView("No Focus Data", systemImage: "chart.pie")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(pieStats) { stat in
                    SectorMark(
                        angle: .value("Duration", stat.totalSeconds),
                        innerRadius: .ratio(0.48),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Category", stat.category.rawValue))
                    .annotation(position: .overlay) {
                        if percentage(for: stat) >= 0.05 {
                            Text(String(format: "%.0f%%", percentage(for: stat) * 100))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .chartForegroundStyleScale(
                    domain: FocusCategory.allCases.map(\.rawValue),
                    range: FocusCategory.allCases.map { ThemePalette.categoryColor($0, for: colorScheme) }
                )
                .chartLegend(position: .bottom, alignment: .center, spacing: 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }

    private func timelineSection(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Timeline", systemImage: "calendar")
                .font(.headline)

            dateSelector(
                title: "Day",
                valueText: timelineDate.formatted(.dateTime.year().month().day()),
                step: .day,
                isPopoverPresented: $isDayCalendarPresented
            )

            dateSelector(
                title: "Week",
                valueText: weekRangeText,
                step: .weekOfYear,
                isPopoverPresented: $isWeekCalendarPresented
            )

            TodayTimelineChartView(
                sessions: sessions,
                selectedDate: $timelineDate,
                onHoverWindow: { hoveredTimelineWindow = $0 }
            )
            .frame(width: max(120, width), height: max(82, height - 92))
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
    }

    private func dateSelector(
        title: String,
        valueText: String,
        step: Calendar.Component,
        isPopoverPresented: Binding<Bool>
    ) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)

            Button {
                timelineDate = calendar.date(byAdding: step, value: -1, to: timelineDate) ?? timelineDate
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                isPopoverPresented.wrappedValue = true
            } label: {
                Text(valueText)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .popover(isPresented: isPopoverPresented, arrowEdge: .top) {
                VStack(spacing: 12) {
                    Text("Select a Date")
                        .font(.headline)
                    DatePicker(
                        "",
                        selection: $timelineDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                    Button("Done") {
                        isPopoverPresented.wrappedValue = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(12)
                .frame(width: 300)
            }

            Button {
                guard canMoveTimelineForward(by: step) else { return }
                let candidate = calendar.date(byAdding: step, value: 1, to: timelineDate) ?? timelineDate
                timelineDate = min(candidate, Date())
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!canMoveTimelineForward(by: step))
        }
    }

    private var timeBuckets: [TimeBucket] {
        StatsCalculator.buckets(for: sessions, range: selectedRange, window: statsWindow, calendar: calendar)
    }

    private var pieWindow: StatsWindow {
        hoveredTimelineWindow ?? statsWindow
    }

    private var pieStats: [CategoryStat] {
        StatsCalculator.categoryStats(from: sessions, in: pieWindow)
    }

    private var pieTotalSeconds: Int {
        pieStats.reduce(0) { $0 + $1.totalSeconds }
    }

    private func percentage(for stat: CategoryStat) -> Double {
        guard pieTotalSeconds > 0 else { return 0 }
        return Double(stat.totalSeconds) / Double(pieTotalSeconds)
    }

    private var pieWindowLabel: String {
        if hoveredTimelineWindow != nil {
            return "Timeline hover"
        }
        return selectedRange.rawValue
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
        String(format: "%.0f", abs(bucket.changeRatio * 100))
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

    private func shouldHighlightBucketBackground(_ bucket: TimeBucket) -> Bool {
        switch selectedRange {
        case .hour:
            let hour = calendar.component(.hour, from: bucket.start)
            return hour >= 9 && hour < 17
        case .day:
            let weekday = calendar.component(.weekday, from: bucket.start)
            return weekday >= 2 && weekday <= 6
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

    private var windowStartText: String {
        switch selectedRange {
        case .hour:
            return statsWindow.start.formatted(.dateTime.year().month().day().hour().minute())
        case .day, .week, .month:
            return statsWindow.start.formatted(.dateTime.year().month().day())
        }
    }

    private var windowEndText: String {
        let end = statsWindow.end.addingTimeInterval(-1)
        switch selectedRange {
        case .hour:
            return end.formatted(.dateTime.year().month().day().hour().minute())
        case .day, .week, .month:
            return end.formatted(.dateTime.year().month().day())
        }
    }

    private var weekRangeText: String {
        let start = isoCalendar.dateInterval(of: .weekOfYear, for: timelineDate)?.start
            ?? calendar.startOfDay(for: timelineDate)
        let end = isoCalendar.date(byAdding: .day, value: 6, to: start) ?? start
        return "\(start.formatted(.dateTime.month().day()))–\(end.formatted(.dateTime.month().day()))"
    }

    private func canMoveTimelineForward(by component: Calendar.Component) -> Bool {
        if component == .weekOfYear {
            let selectedWeek = isoCalendar.dateInterval(of: .weekOfYear, for: timelineDate)?.start
                ?? calendar.startOfDay(for: timelineDate)
            let currentWeek = isoCalendar.dateInterval(of: .weekOfYear, for: Date())?.start
                ?? calendar.startOfDay(for: Date())
            return selectedWeek < currentWeek
        }

        return calendar.startOfDay(for: timelineDate) < calendar.startOfDay(for: Date())
    }
}
