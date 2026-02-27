import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var showClearConfirm = false

    var body: some View {
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
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
        .alert("确认清除所有历史数据？", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                NotificationCenter.default.post(name: .clearAllHistoryRequested, object: nil)
            }
        }
    }
}
