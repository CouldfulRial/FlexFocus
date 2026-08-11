import SwiftUI
import Charts
import AppKit
import Combine

struct MainContentView: View {
    static let leftSidebarMinWidth: CGFloat = 300
    static let rightSidebarMinWidth: CGFloat = 360
    static let centerMinWidth: CGFloat = 380
    static let splitterWidth: CGFloat = 8
    private static let statsHeaderHeight: CGFloat = 124
    private static let statsSectionSpacing: CGFloat = 12
    private static let statsOuterPadding: CGFloat = 12
    private static let statsSectionMinHeight: CGFloat = 180

    static let minimumWindowWidth: CGFloat = leftSidebarMinWidth + rightSidebarMinWidth + centerMinWidth + (splitterWidth * 2)
    static let minimumWindowHeight: CGFloat = statsHeaderHeight + (statsSectionSpacing * 2) + (statsOuterPadding * 2) + (statsSectionMinHeight * 3)

    private let leftSidebarMinWidth = Self.leftSidebarMinWidth
    private let rightSidebarMinWidth = Self.rightSidebarMinWidth
    private let centerMinWidth = Self.centerMinWidth
    private let splitterWidth = Self.splitterWidth

    @State private var sessions: [FocusSession] = []
    @StateObject private var viewModel = FocusViewModel()
    @State private var selectedCategory: FocusCategory = .research
    @State private var selectedRange: StatisticsRange = .week
    @State private var didConfigureWindow = false
    @State private var leftSidebarWidth: CGFloat = 320
    @State private var rightSidebarWidth: CGFloat = 380
    @State private var leftDragStartWidth: CGFloat?
    @State private var rightDragStartWidth: CGFloat?
    private let sessionStore = SessionStore()

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let leftWidth = clampedLeftWidth(totalWidth: totalWidth)
            let rightWidth = clampedRightWidth(totalWidth: totalWidth)
            let centerVisibleWidth = max(
                centerMinWidth,
                totalWidth - leftWidth - rightWidth - (splitterWidth * 2) - 24
            )

            ZStack {
                FocusTimerView(
                    phase: viewModel.phase,
                    elapsedFocusSeconds: viewModel.elapsedFocusSeconds,
                    remainingBreakSeconds: viewModel.remainingBreakSeconds,
                    currentCategory: viewModel.currentCategory,
                    contentMaxWidth: centerVisibleWidth,
                    onStart: {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        viewModel.openCategoryPicker()
                    },
                    onEndFocus: { endFocusAndPersist() },
                    onSkipBreak: { viewModel.skipBreak() }
                )
                .frame(width: centerVisibleWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                HStack(spacing: 0) {
                    StatsSidebarView(
                        sessions: sessions,
                        selectedRange: $selectedRange
                    )
                    .frame(width: leftWidth)
                    .frame(maxHeight: .infinity)

                    sidebarSplitterHandle()
                        .gesture(leftSidebarDragGesture(totalWidth: totalWidth))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .animation(nil, value: leftSidebarWidth)

                HStack(spacing: 0) {
                    sidebarSplitterHandle()
                        .gesture(rightSidebarDragGesture(totalWidth: totalWidth))

                    FocusHistoryView(
                        sessions: sessions,
                        onUpdateSession: updateSession
                    )
                    .frame(width: rightWidth)
                    .frame(maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .animation(nil, value: rightSidebarWidth)
            }
            .onAppear {
                normalizeSidebarWidths(totalWidth: totalWidth)
            }
            .onChange(of: totalWidth) { _, newValue in
                normalizeSidebarWidths(totalWidth: newValue)
            }
        }
        .sheet(isPresented: $viewModel.isCategoryPickerPresented) {
            CategorySelectionSheet(
                selectedCategory: $selectedCategory,
                onCancel: {
                    viewModel.isCategoryPickerPresented = false
                },
                onSubmit: {
                    viewModel.startFocus(category: selectedCategory)
                }
            )
            .frame(width: 360)
            .padding()
            .onAppear {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
            }
        }
        .alert("Start a break?", isPresented: breakConfirmationBinding) {
            Button("Not Now") {
                viewModel.skipBreak()
            }
            Button("Start Break") {
                viewModel.confirmBreak()
            }
        } message: {
            if let completed = viewModel.consumeCompletedFocusIfNeeded() {
                Text("Break duration: \(formatDuration(max(60, completed.durationSeconds / 5)))")
            }
        }
        .onAppear {
            sessions = sessionStore.load().sorted(by: { $0.startTime > $1.startTime })
            sessionStore.save(sessions)
            configureWindowIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clearAllHistoryRequested)) { _ in
            sessions = []
            sessionStore.clear()
        }
    }

    private func endFocusAndPersist() {
        viewModel.endFocusManually()
        if let completed = viewModel.consumeCompletedFocusIfNeeded() {
            let item = FocusSession(
                category: completed.category,
                startTime: completed.startTime,
                endTime: completed.endTime,
                durationSeconds: completed.durationSeconds
            )
            sessions.insert(item, at: 0)
            sessions.sort(by: { $0.startTime > $1.startTime })
            sessionStore.save(sessions)
        }
    }

    private func updateSession(
        sessionID: UUID,
        category: FocusCategory,
        startTime: Date,
        endTime: Date
    ) {
        guard endTime > startTime else { return }
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].category = category
        sessions[index].startTime = startTime
        sessions[index].endTime = endTime
        sessions[index].durationSeconds = max(1, Int(endTime.timeIntervalSince(startTime)))
        sessions.sort(by: { $0.startTime > $1.startTime })
        sessionStore.save(sessions)
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
            window.minSize = NSSize(width: Self.minimumWindowWidth, height: Self.minimumWindowHeight)
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func sidebarSplitterHandle() -> some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.45))
            .frame(width: splitterWidth)
            .contentShape(Rectangle())
    }

    private func maxSidebarWidth(totalWidth: CGFloat) -> CGFloat {
        max(leftSidebarMinWidth, (totalWidth - centerMinWidth) / 2 - splitterWidth)
    }

    private func clampedLeftWidth(totalWidth: CGFloat) -> CGFloat {
        snapped(min(max(leftSidebarWidth, leftSidebarMinWidth), maxSidebarWidth(totalWidth: totalWidth)))
    }

    private func clampedRightWidth(totalWidth: CGFloat) -> CGFloat {
        snapped(min(max(rightSidebarWidth, rightSidebarMinWidth), maxSidebarWidth(totalWidth: totalWidth)))
    }

    private func normalizeSidebarWidths(totalWidth: CGFloat) {
        let left = clampedLeftWidth(totalWidth: totalWidth)
        let right = clampedRightWidth(totalWidth: totalWidth)

        if leftSidebarWidth != left {
            leftSidebarWidth = left
        }
        if rightSidebarWidth != right {
            rightSidebarWidth = right
        }
    }

    private func leftSidebarDragGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if leftDragStartWidth == nil {
                    leftDragStartWidth = leftSidebarWidth
                }

                let start = leftDragStartWidth ?? leftSidebarWidth
                let maxLeft = maxSidebarWidth(totalWidth: totalWidth)
                let next = min(max(start + value.translation.width, leftSidebarMinWidth), maxLeft)
                leftSidebarWidth = snapped(next)
            }
            .onEnded { _ in
                leftDragStartWidth = nil
                normalizeSidebarWidths(totalWidth: totalWidth)
            }
    }

    private func rightSidebarDragGesture(totalWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if rightDragStartWidth == nil {
                    rightDragStartWidth = rightSidebarWidth
                }

                let start = rightDragStartWidth ?? rightSidebarWidth
                let maxRight = maxSidebarWidth(totalWidth: totalWidth)
                let next = min(max(start - value.translation.width, rightSidebarMinWidth), maxRight)
                rightSidebarWidth = snapped(next)
            }
            .onEnded { _ in
                rightDragStartWidth = nil
                normalizeSidebarWidths(totalWidth: totalWidth)
            }
    }

    private func snapped(_ value: CGFloat) -> CGFloat {
        (value * 2).rounded() / 2
    }
}
