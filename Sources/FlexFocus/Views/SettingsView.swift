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
                TextField("搜索屏蔽词汇", text: $vocabularySearchText)
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
                            settings.removeBlockedWord(selectedVocabularyWord)
                            self.selectedVocabularyWord = nil
                        }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedVocabularyWord == nil)

                    Spacer()

                    Button("重置默认") {
                        settings.resetDefaultBlockedWords()
                        selectedVocabularyWord = nil
                    }
                }

                Text("可删除任意屏蔽词汇（包括默认词）；点击“重置默认”可恢复。")
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
                        settings.addBlockedWord(newVocabularyWord)
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
    }

    private var filteredVocabulary: [String] {
        let query = vocabularySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return settings.blockedWordsList }
        return settings.blockedWordsList.filter { $0.localizedCaseInsensitiveContains(query) }
    }
}
