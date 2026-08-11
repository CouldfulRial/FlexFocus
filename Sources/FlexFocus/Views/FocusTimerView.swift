import SwiftUI

struct FocusTimerView: View {
    let phase: TimerPhase
    let elapsedFocusSeconds: Int
    let remainingBreakSeconds: Int
    let currentCategory: FocusCategory?
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

            if let currentCategory {
                Text("Category: \(currentCategory.rawValue)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: max(220, contentMaxWidth - 40))
                    .padding(.horizontal, 12)
            }

            HStack(spacing: 12) {
                if case .focusing = phase {
                    Button("End Focus", role: .destructive, action: onEndFocus)
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Start Focus", action: onStart)
                        .buttonStyle(.borderedProminent)
                }

                if case .breaking = phase {
                    Button("Skip Break", action: onSkipBreak)
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
            return "Ready"
        case .focusing:
            return "Focusing"
        case .awaitingBreakConfirmation:
            return "Focus Complete"
        case .breaking:
            return "On Break"
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
}
