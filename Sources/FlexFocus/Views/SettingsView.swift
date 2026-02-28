import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var showClearConfirm = false
    @State private var selectedVocabularyWord: String?
    @State private var showAddVocabularySheet = false
    @State private var newVocabularyWord = ""
    @State private var vocabularySearchText = ""

    var body: some View {
        TabView {
            Form {
                Toggle("专注开始时开启 DND", isOn: $settings.enableDNDOnFocusStart)
                Toggle("专注结束时关闭 DND", isOn: $settings.disableDNDOnFocusEnd)
                Toggle("休息结束发送通知", isOn: $settings.enableBreakNotification)

                Section {
                    Button("清除所有历史数据", role: .destructive) {
                        showClearConfirm = true
                    }
                } footer: {
                    Text("将清除所有专注历史与统计数据，且不可恢复。")
                }
            }
            .tabItem {
                Text("通用")
            }

            VStack(alignment: .leading, spacing: 10) {
                Picker("词汇模式", selection: $settings.vocabularyModeRawValue) {
                    ForEach(VocabularyFilterMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

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

                Text(modeFootnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .tabItem {
                Text("词汇")
            }
        }
        .frame(width: 460, height: 420)
        .sheet(isPresented: $showAddVocabularySheet) {
            VStack(alignment: .leading, spacing: 12) {
                Text("添加屏蔽词汇")
                    .font(.headline)
                TextField("输入新屏蔽词汇", text: $newVocabularyWord)
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
}
