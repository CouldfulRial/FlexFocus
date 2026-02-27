import SwiftUI
import Charts
import AppKit

struct MainContentView: View {
    @State private var sessions: [FocusSession] = []
    @State private var viewModel = FocusViewModel()
    @State private var taskInput = ""
    @State private var selectedRange: StatisticsRange = .week
    @State private var didConfigureWindow = false
    private let sessionStore = SessionStore()

    var body: some View {
        HSplitView {
            StatsSidebarView(
                sessions: sessions,
                selectedRange: $selectedRange
            )
            .frame(minWidth: 300)

            FocusTimerView(
                phase: viewModel.phase,
                elapsedFocusSeconds: viewModel.elapsedFocusSeconds,
                remainingBreakSeconds: viewModel.remainingBreakSeconds,
                currentTask: viewModel.currentTask,
                onStart: {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    viewModel.openTaskInput()
                },
                onEndFocus: { endFocusAndPersist() },
                onSkipBreak: { viewModel.skipBreak() }
            )
            .frame(minWidth: 380)

            FocusHistoryView(sessions: sessions)
                .frame(minWidth: 360)
        }
        .sheet(isPresented: $viewModel.isTaskSheetPresented) {
            TaskInputSheet(
                inputTask: $taskInput,
                quickTasks: recentTasks,
                onCancel: {
                    viewModel.isTaskSheetPresented = false
                    taskInput = ""
                },
                onSubmit: {
                    viewModel.startFocus(task: taskInput)
                    taskInput = ""
                }
            )
            .frame(width: 420)
            .padding()
            .onAppear {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
            }
        }
        .alert("是否开始休息？", isPresented: breakConfirmationBinding) {
            Button("稍后") {
                viewModel.skipBreak()
            }
            Button("开始休息") {
                viewModel.confirmBreak()
            }
        } message: {
            if let completed = viewModel.consumeCompletedFocusIfNeeded() {
                Text("休息时长 \(formatDuration(max(60, completed.durationSeconds / 5)))")
            }
        }
        .onAppear {
            sessions = sessionStore.load().sorted(by: { $0.startTime > $1.startTime })
            configureWindowIfNeeded()
        }
    }

    private var recentTasks: [String] {
        var seen = Set<String>()
        return sessions
            .map(\.task)
            .filter { task in
                if seen.contains(task) { return false }
                seen.insert(task)
                return true
            }
            .prefix(12)
            .map { $0 }
    }

    private func endFocusAndPersist() {
        viewModel.endFocusManually()
        if let completed = viewModel.consumeCompletedFocusIfNeeded() {
            let item = FocusSession(
                task: completed.task,
                startTime: completed.startTime,
                endTime: completed.endTime,
                durationSeconds: completed.durationSeconds
            )
            sessions.insert(item, at: 0)
            sessions.sort(by: { $0.startTime > $1.startTime })
            sessionStore.save(sessions)
        }
    }

    private var breakConfirmationBinding: Binding<Bool> {
        Binding(
            get: {
                if case .awaitingBreakConfirmation = viewModel.phase { return true }
                return false
            },
            set: { newValue in
                if !newValue, case .awaitingBreakConfirmation = viewModel.phase {
                    viewModel.skipBreak()
                }
            }
        )
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minute = seconds / 60
        let second = seconds % 60
        return String(format: "%02d:%02d", minute, second)
    }

    private func configureWindowIfNeeded() {
        guard !didConfigureWindow else { return }
        didConfigureWindow = true

        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            guard let window = NSApplication.shared.windows.first else { return }
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
}
