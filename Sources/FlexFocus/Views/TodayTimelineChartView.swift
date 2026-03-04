import SwiftUI

private enum TimelineMode {
    case day
    case week
}

private struct TimelineSegment: Identifiable {
    let start: Date
    let end: Date

    var id: String {
        "\(start.timeIntervalSince1970)-\(end.timeIntervalSince1970)"
    }
}

private struct TimelineTick: Identifiable {
    let id = UUID()
    let label: String
    let date: Date
}

struct TodayTimelineChartView: View {
    let sessions: [FocusSession]
    let selectedDate: Date

    @Environment(\.colorScheme) private var colorScheme
    private let calendar = Calendar.current

    private var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let height = max(1, proxy.size.height)
            let panelGap: CGFloat = 10
            let panelHeight = max(68, (height - panelGap) / 2)

            VStack(spacing: panelGap) {
                timelinePanel(mode: .day, width: width, height: panelHeight)
                timelinePanel(mode: .week, width: width, height: panelHeight)
            }
            .frame(width: width, height: height, alignment: .top)
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func timelinePanel(mode: TimelineMode, width: CGFloat, height: CGFloat) -> some View {
        let topPadding: CGFloat = 6
        let bottomPadding: CGFloat = 6
        let labelReservedHeight: CGFloat = 16
        let summaryReservedHeight: CGFloat = 16
        let verticalGap: CGFloat = 8
        let summaryGap: CGFloat = 6
        let barTop = topPadding
        let barHeight = max(24, height - topPadding - bottomPadding - labelReservedHeight - summaryReservedHeight - verticalGap - summaryGap)
        let barBottom = barTop + barHeight
        let labelsTop = barBottom + verticalGap
        let summaryTop = labelsTop + summaryGap + labelReservedHeight

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.08))
                .frame(width: width, height: barHeight)
                .offset(x: 0, y: barTop)

            ForEach(segments(for: mode)) { segment in
                Rectangle()
                    .fill(ThemePalette.focusColor(for: colorScheme))
                    .frame(width: segmentWidth(segment, totalWidth: width, mode: mode), height: barHeight)
                    .offset(x: positionX(for: segment.start, totalWidth: width, mode: mode), y: barTop)
            }

            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                .frame(width: width, height: barHeight)
                .offset(x: 0, y: barTop)

            if mode == .day {
                ForEach(dayTicks) { tick in
                    Path { path in
                        let x = positionX(for: tick.date, totalWidth: width, mode: .day)
                        path.move(to: CGPoint(x: x, y: barTop))
                        path.addLine(to: CGPoint(x: x, y: barBottom))
                    }
                    .stroke(
                        Color.secondary.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                }

                tickLabel("00:00", x: 0, y: labelsTop, totalWidth: width, alignment: .leading)
                tickLabel("09:00", x: positionX(for: dayTicks[1].date, totalWidth: width, mode: .day), y: labelsTop, totalWidth: width, alignment: .center)
                tickLabel("12:00", x: positionX(for: dayTicks[2].date, totalWidth: width, mode: .day), y: labelsTop, totalWidth: width, alignment: .center)
                tickLabel("17:00", x: positionX(for: dayTicks[3].date, totalWidth: width, mode: .day), y: labelsTop, totalWidth: width, alignment: .center)
                tickLabel("23:59", x: width, y: labelsTop, totalWidth: width, alignment: .trailing)

                if isSelectedDateToday {
                    Path { path in
                        let nowX = positionX(for: nowMarkerDate, totalWidth: width, mode: .day)
                        path.move(to: CGPoint(x: nowX, y: barTop - 3))
                        path.addLine(to: CGPoint(x: nowX, y: barBottom + 3))
                    }
                    .stroke(ThemePalette.nowLineColor(for: colorScheme), lineWidth: 2)
                }
            } else {
                let cellWidth = width / 7

                ForEach(1..<7, id: \.self) { index in
                    Path { path in
                        let x = CGFloat(index) * cellWidth
                        path.move(to: CGPoint(x: x, y: barTop))
                        path.addLine(to: CGPoint(x: x, y: barBottom))
                    }
                    .stroke(
                        Color.secondary.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                }

                Rectangle()
                    .stroke(Color.black, lineWidth: 1.2)
                    .frame(width: cellWidth, height: barHeight)
                    .offset(x: CGFloat(selectedDayIndexInWeek) * cellWidth, y: barTop)

                ForEach(Array(weekDayLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: (CGFloat(index) + 0.5) * cellWidth, y: labelsTop + 7)
                }
            }

            summaryText(for: mode)
                .font(.caption)
                .frame(width: width, alignment: .center)
                .offset(x: 0, y: summaryTop)
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    private var selectedDayStart: Date {
        calendar.startOfDay(for: selectedDate)
    }

    private var selectedDayEnd: Date {
        calendar.date(byAdding: .day, value: 1, to: selectedDayStart) ?? selectedDayStart
    }

    private var weekStart: Date {
        isoCalendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDayStart
    }

    private var weekEnd: Date {
        isoCalendar.date(byAdding: .day, value: 7, to: weekStart) ?? selectedDayEnd
    }

    private var dayTicks: [TimelineTick] {
        let nine = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDayStart) ?? selectedDayStart
        let twelve = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDayStart) ?? selectedDayStart
        let seventeen = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: selectedDayStart) ?? selectedDayStart
        let endTick = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: selectedDayStart) ?? selectedDayEnd.addingTimeInterval(-60)

        return [
            TimelineTick(label: "00:00", date: selectedDayStart),
            TimelineTick(label: "09:00", date: nine),
            TimelineTick(label: "12:00", date: twelve),
            TimelineTick(label: "17:00", date: seventeen),
            TimelineTick(label: "23:59", date: endTick)
        ]
    }

    private var weekDayLabels: [String] {
        ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    }

    private var selectedDayIndexInWeek: Int {
        let days = isoCalendar.dateComponents([.day], from: weekStart, to: selectedDayStart).day ?? 0
        return min(max(days, 0), 6)
    }

    private var isSelectedDateToday: Bool {
        calendar.isDate(selectedDate, inSameDayAs: Date())
    }

    private var nowMarkerDate: Date {
        let now = Date()
        var components = calendar.dateComponents([.hour, .minute, .second], from: now)
        components.year = calendar.component(.year, from: selectedDayStart)
        components.month = calendar.component(.month, from: selectedDayStart)
        components.day = calendar.component(.day, from: selectedDayStart)
        return calendar.date(from: components) ?? selectedDayStart
    }

    private func segments(for mode: TimelineMode) -> [TimelineSegment] {
        let rangeStart = mode == .day ? selectedDayStart : weekStart
        let rangeEnd = mode == .day ? selectedDayEnd : weekEnd

        return sessions
            .sorted { $0.startTime < $1.startTime }
            .compactMap { session in
                let lower = max(session.startTime, rangeStart)
                let upper = min(session.endTime, rangeEnd)
                guard upper > lower else { return nil }
                return TimelineSegment(start: lower, end: upper)
            }
    }

    private func positionX(for date: Date, totalWidth: CGFloat, mode: TimelineMode) -> CGFloat {
        let rangeStart = mode == .day ? selectedDayStart : weekStart
        let rangeEnd = mode == .day ? selectedDayEnd : weekEnd
        let duration = max(1, rangeEnd.timeIntervalSince(rangeStart))
        let seconds = min(max(date.timeIntervalSince(rangeStart), 0), duration)
        return CGFloat(seconds / duration) * totalWidth
    }

    private func segmentWidth(_ segment: TimelineSegment, totalWidth: CGFloat, mode: TimelineMode) -> CGFloat {
        let width = positionX(for: segment.end, totalWidth: totalWidth, mode: mode)
            - positionX(for: segment.start, totalWidth: totalWidth, mode: mode)
        return max(1, width)
    }

    private func totalFocusedSeconds(in range: DateInterval) -> Int {
        sessions.reduce(0) { partial, session in
            let lower = max(session.startTime, range.start)
            let upper = min(session.endTime, range.end)
            guard upper > lower else { return partial }
            return partial + Int(upper.timeIntervalSince(lower))
        }
    }

    private func summaryText(for mode: TimelineMode) -> Text {
        let focusColor = ThemePalette.focusColor(for: colorScheme)

        switch mode {
        case .day:
            let focusedSeconds = totalFocusedSeconds(in: DateInterval(start: selectedDayStart, end: selectedDayEnd))
            let focusHours = Double(focusedSeconds) / 3600.0
            let percent = (focusHours / 8.0) * 100.0
            return Text("这天共专注")
                + Text(String(format: "%.1f", focusHours)).foregroundColor(focusColor)
                + Text("小时，占8小时的")
                + Text(String(format: "%.1f", percent)).foregroundColor(focusColor)
                + Text("%")
        case .week:
            let focusedSeconds = totalFocusedSeconds(in: DateInterval(start: weekStart, end: weekEnd))
            let focusHours = Double(focusedSeconds) / 3600.0
            let percent = (focusHours / 40.0) * 100.0
            return Text("这周共专注")
                + Text(String(format: "%.1f", focusHours)).foregroundColor(focusColor)
                + Text("小时，占40小时的")
                + Text(String(format: "%.1f", percent)).foregroundColor(focusColor)
                + Text("%")
        }
    }

    @ViewBuilder
    private func tickLabel(_ label: String, x: CGFloat, y: CGFloat, totalWidth: CGFloat, alignment: Alignment) -> some View {
        switch alignment {
        case .leading:
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: totalWidth, alignment: .leading)
                .offset(x: 0, y: y)
        case .trailing:
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: totalWidth, alignment: .trailing)
                .offset(x: 0, y: y)
        default:
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .position(x: x, y: y + 7)
        }
    }
}
