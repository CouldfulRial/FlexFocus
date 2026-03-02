import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var showClearConfirm = false
    @State private var selectedVocabularyWord: String?
    @State private var showAddVocabularySheet = false
    @State private var newVocabularyWord = ""
    @State private var vocabularySearchText = ""
    @State private var storageDirectoryURL = StoragePathManager.shared.currentDataDirectoryURL

    var body: some View {
        TabView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingsSection(
                        title: "专注与通知",
                        subtitle: "控制专注流程与提醒行为"
                    ) {
                        Toggle("专注开始时开启 DND", isOn: $settings.enableDNDOnFocusStart)
                        Toggle("专注结束时关闭 DND", isOn: $settings.disableDNDOnFocusEnd)
                        Toggle("休息结束发送通知", isOn: $settings.enableBreakNotification)
                    }

                    settingsSection(
                        title: "主题",
                        subtitle: "控制界面主题与 Dark 模式配色策略"
                    ) {
                        Picker("主题模式", selection: $settings.themeModeRawValue) {
                            ForEach(AppThemeMode.allCases) { mode in
                                Text(mode.title).tag(mode.rawValue)
                            }
                        }

                        Toggle("Dark 模式主题色反色", isOn: $settings.invertThemeColorsInDarkMode)
                    }

                    settingsSection(
                        title: "数据",
                        subtitle: "管理本地历史和统计数据"
                    ) {
                        Button("清除所有历史数据", role: .destructive) {
                            showClearConfirm = true
                        }

                        Text("将清除所有专注历史与统计数据，且不可恢复。")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("数据存储位置：")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(storageDirectoryURL.path)
                                .font(.caption)
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                Button("打开位置") {
                                    NSWorkspace.shared.open(storageDirectoryURL)
                                }
                                .buttonStyle(.bordered)

                                Button("更改位置") {
                                    changeStorageLocation()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .tabItem {
                Label("通用", systemImage: "gearshape")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingsSection(
                        title: "词汇模式",
                        subtitle: "选择词汇统计策略"
                    ) {
                        Picker("词汇模式", selection: $settings.vocabularyModeRawValue) {
                            ForEach(VocabularyFilterMode.allCases) { mode in
                                Text(mode.title).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    settingsSection(
                        title: "词汇列表",
                        subtitle: modeFootnote
                    ) {
                        TextField(searchPlaceholder, text: $vocabularySearchText)
                            .textFieldStyle(.roundedBorder)

                        List(filteredVocabulary, id: \.self, selection: $selectedVocabularyWord) { word in
                            Text(word)
                        }
                        .frame(minHeight: 260)

                        HStack(spacing: 12) {
                            Button {
                                newVocabularyWord = ""
                                showAddVocabularySheet = true
                            } label: {
                                Image(systemName: "plus")
                            }

                            Button {
                                if let selectedVocabularyWord {
                                    settings.removeCurrentModeWord(selectedVocabularyWord)
                                    self.selectedVocabularyWord = nil
                                }
                            } label: {
                                Image(systemName: "minus")
                            }
                            .disabled(selectedVocabularyWord == nil)

                            Spacer()

                            Button("重置默认") {
                                settings.resetCurrentModeWords()
                                selectedVocabularyWord = nil
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .tabItem {
                Label("词汇", systemImage: "textformat")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingsSection(
                        title: "应用信息",
                        subtitle: "版本与作者"
                    ) {
                        HStack {
                            Text("版本")
                            Spacer()
                            Text(appVersionText)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("作者")
                            Spacer()
                            Text("Yifan Gong")
                                .foregroundStyle(.secondary)
                        }
                    }

                    settingsSection(
                        title: "项目链接",
                        subtitle: "GitHub 仓库"
                    ) {
                        Link("https://github.com/CouldfulRial/FlexFocus", destination: URL(string: "https://github.com/CouldfulRial/FlexFocus")!)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }
        }
        .frame(width: 520, height: 500)
        .padding(.top, 8)
        .sheet(isPresented: $showAddVocabularySheet) {
            VStack(alignment: .leading, spacing: 12) {
                Text(currentMode == .blacklist ? "添加屏蔽词汇" : "添加白名单词汇")
                    .font(.headline)
                TextField(currentMode == .blacklist ? "输入新屏蔽词汇" : "输入新白名单词汇", text: $newVocabularyWord)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("取消") {
                        showAddVocabularySheet = false
                    }
                    Button("添加") {
                        settings.addCurrentModeWord(newVocabularyWord)
                        showAddVocabularySheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newVocabularyWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .frame(width: 320)
        }
        .alert("确认清除所有历史数据？", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                NotificationCenter.default.post(name: .clearAllHistoryRequested, object: nil)
            }
        }
        .onChange(of: settings.vocabularyModeRawValue) { _, _ in
            selectedVocabularyWord = nil
            vocabularySearchText = ""
        }
        .onReceive(NotificationCenter.default.publisher(for: .storageDirectoryDidChange)) { _ in
            storageDirectoryURL = StoragePathManager.shared.currentDataDirectoryURL
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.06))
        )
    }

    private var filteredVocabulary: [String] {
        let query = vocabularySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let source = settings.currentModeWordsList
        guard !query.isEmpty else { return source }
        return source.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    private var currentMode: VocabularyFilterMode {
        VocabularyFilterMode(rawValue: settings.vocabularyModeRawValue) ?? .blacklist
    }

    private var searchPlaceholder: String {
        switch currentMode {
        case .blacklist:
            return "搜索屏蔽词汇"
        case .whitelist:
            return "搜索白名单词汇"
        }
    }

    private var modeFootnote: String {
        switch currentMode {
        case .blacklist:
            return "黑名单模式：命中这些词汇将被过滤；可通过“重置默认”恢复默认屏蔽词汇。"
        case .whitelist:
            return "白名单模式：仅统计白名单词汇；“重置默认”会清空白名单。"
        }
    }

    private var appVersionText: String {
        "1.0.0 (2026)"
    }

    private func changeStorageLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = storageDirectoryURL
        panel.prompt = "选择"

        if panel.runModal() == .OK, let selected = panel.url {
            StoragePathManager.shared.updateDataDirectory(to: selected)
            storageDirectoryURL = StoragePathManager.shared.currentDataDirectoryURL
        }
    }
}
