import SwiftUI

private enum TodaySegmentType {
    case focus
    case rest
}

private struct TodaySegment: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let type: TodaySegmentType
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

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let height = max(1, proxy.size.height)
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

                ForEach(segments.filter { $0.type == .rest }) { segment in
                    Rectangle()
                        .fill(ThemePalette.breakColor(for: colorScheme))
                        .frame(width: segmentWidth(segment, totalWidth: width), height: barHeight)
                        .offset(x: positionX(for: segment.start, totalWidth: width), y: barTop)
                }

                ForEach(segments.filter { $0.type == .focus }) { segment in
                    Rectangle()
                        .fill(ThemePalette.focusColor(for: colorScheme))
                        .frame(width: segmentWidth(segment, totalWidth: width), height: barHeight)
                        .offset(x: positionX(for: segment.start, totalWidth: width), y: barTop)
                }

                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                    .frame(width: width, height: barHeight)
                    .offset(x: 0, y: barTop)

                ForEach(ticks) { tick in
                    Path { path in
                        let x = positionX(for: tick.date, totalWidth: width)
                        path.move(to: CGPoint(x: x, y: barTop))
                        path.addLine(to: CGPoint(x: x, y: barBottom))
                    }
                    .stroke(
                        Color.secondary.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                }

                tickLabel("00:00", x: 0, y: labelsTop, totalWidth: width, alignment: .leading)
                tickLabel("09:00", x: positionX(for: ticks[1].date, totalWidth: width), y: labelsTop, totalWidth: width, alignment: .center)
                tickLabel("12:00", x: positionX(for: ticks[2].date, totalWidth: width), y: labelsTop, totalWidth: width, alignment: .center)
                tickLabel("17:00", x: positionX(for: ticks[3].date, totalWidth: width), y: labelsTop, totalWidth: width, alignment: .center)
                tickLabel("23:59", x: width, y: labelsTop, totalWidth: width, alignment: .trailing)

                if isSelectedDateToday {
                    Path { path in
                        let nowX = positionX(for: nowMarkerDate, totalWidth: width)
                        path.move(to: CGPoint(x: nowX, y: barTop - 3))
                        path.addLine(to: CGPoint(x: nowX, y: barBottom + 3))
                    }
                    .stroke(ThemePalette.nowLineColor(for: colorScheme), lineWidth: 2)
                }

                summaryText
                    .font(.caption)
                    .frame(width: width, alignment: .center)
                    .offset(x: 0, y: summaryTop)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxHeight: .infinity)
    }

    private var dayStart: Date {
        calendar.startOfDay(for: selectedDate)
    }

    private var dayEnd: Date {
        calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
    }

    private var dayDuration: TimeInterval {
        max(1, dayEnd.timeIntervalSince(dayStart))
    }

    private var isSelectedDateToday: Bool {
        calendar.isDate(selectedDate, inSameDayAs: Date())
    }

    private var nowMarkerDate: Date {
        let now = Date()
        var components = calendar.dateComponents([.hour, .minute, .second], from: now)
        components.year = calendar.component(.year, from: dayStart)
        components.month = calendar.component(.month, from: dayStart)
        components.day = calendar.component(.day, from: dayStart)
        return calendar.date(from: components) ?? dayStart
    }

    private var segments: [TodaySegment] {
        let sourceSessions = sessions.sorted { $0.startTime < $1.startTime }
        var result: [TodaySegment] = []

        for session in sourceSessions {
            if let focusInterval = clampedInterval(start: session.startTime, end: session.endTime) {
                result.append(TodaySegment(start: focusInterval.start, end: focusInterval.end, type: .focus))
            }

            let breakStart = session.endTime
            let breakDuration = max(60, session.durationSeconds / 5)
            let breakEnd = breakStart.addingTimeInterval(TimeInterval(breakDuration))

            if let breakInterval = clampedInterval(start: breakStart, end: breakEnd) {
                result.append(TodaySegment(start: breakInterval.start, end: breakInterval.end, type: .rest))
            }
        }

        return result.sorted { lhs, rhs in
            if lhs.start == rhs.start {
                return lhs.type == .rest && rhs.type == .focus
            }
            return lhs.start < rhs.start
        }
    }

    private var ticks: [TimelineTick] {
        let nine = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dayStart) ?? dayStart
        let twelve = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dayStart) ?? dayStart
        let seventeen = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dayStart) ?? dayStart
        let endTick = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: dayStart) ?? dayEnd.addingTimeInterval(-60)

        return [
            TimelineTick(label: "00:00", date: dayStart),
            TimelineTick(label: "09:00", date: nine),
            TimelineTick(label: "12:00", date: twelve),
            TimelineTick(label: "17:00", date: seventeen),
            TimelineTick(label: "23:59", date: endTick)
        ]
    }

    private func positionX(for date: Date, totalWidth: CGFloat) -> CGFloat {
        let seconds = min(max(date.timeIntervalSince(dayStart), 0), dayDuration)
        return CGFloat(seconds / dayDuration) * totalWidth
    }

    private func segmentWidth(_ segment: TodaySegment, totalWidth: CGFloat) -> CGFloat {
        let width = positionX(for: segment.end, totalWidth: totalWidth) - positionX(for: segment.start, totalWidth: totalWidth)
        return max(1, width)
    }

    private func clampedInterval(start: Date, end: Date) -> DateInterval? {
        let lower = max(start, dayStart)
        let upper = min(end, dayEnd)
        guard upper > lower else { return nil }
        return DateInterval(start: lower, end: upper)
    }

    private var totalFocusedSeconds: Int {
        sessions.reduce(0) { partial, session in
            partial + overlapSeconds(start: session.startTime, end: session.endTime)
        }
    }

    private var summaryText: Text {
        let focusHours = Double(totalFocusedSeconds) / 3600.0
        let percent = (focusHours / 8.0) * 100.0
        let color = ThemePalette.focusColor(for: colorScheme)

        return Text("共专注 ")
            + Text(String(format: "%.1f", focusHours)).foregroundColor(color)
            + Text(" 小时，占8小时的 ")
            + Text(String(format: "%.1f", percent)).foregroundColor(color)
            + Text("%")
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

    private func overlapSeconds(start: Date, end: Date) -> Int {
        let lower = max(start, dayStart)
        let upper = min(end, dayEnd)
        guard upper > lower else { return 0 }
        return Int(upper.timeIntervalSince(lower))
    }
}