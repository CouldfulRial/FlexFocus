import SwiftUI

struct FocusTimerView: View {
    let phase: TimerPhase
    let elapsedFocusSeconds: Int
    let remainingBreakSeconds: Int
    let currentTask: String
    let onStart: () -> Void
    let onEndFocus: () -> Void
    let onSkipBreak: () -> Void

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
                Text("任务：\(currentTask)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
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
            return .red
        case .breaking:
            return .green
        default:
            return .primary
        }
    }
}
