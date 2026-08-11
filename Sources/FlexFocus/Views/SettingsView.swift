import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var showClearConfirm = false
    @State private var storageDirectoryURL = StoragePathManager.shared.currentDataDirectoryURL

    var body: some View {
        TabView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingsSection(
                        title: "Focus and Notifications",
                        subtitle: "Control the focus workflow and break alerts."
                    ) {
                        Toggle("Enable DND when focus starts", isOn: $settings.enableDNDOnFocusStart)
                        Toggle("Disable DND when focus ends", isOn: $settings.disableDNDOnFocusEnd)
                        Toggle("Notify when a break ends", isOn: $settings.enableBreakNotification)
                    }

                    settingsSection(
                        title: "Appearance",
                        subtitle: "Control the app theme and dark-mode colors."
                    ) {
                        Picker("Theme", selection: $settings.themeModeRawValue) {
                            ForEach(AppThemeMode.allCases) { mode in
                                Text(mode.title).tag(mode.rawValue)
                            }
                        }

                        Toggle("Invert accent colors in Dark Mode", isOn: $settings.invertThemeColorsInDarkMode)
                    }

                    settingsSection(
                        title: "Data",
                        subtitle: "Manage local focus history and statistics."
                    ) {
                        Button("Clear All History", role: .destructive) {
                            showClearConfirm = true
                        }

                        Text("This permanently removes all focus history and statistics.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Data storage location")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(storageDirectoryURL.path)
                                .font(.caption)
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                Button("Open Location") {
                                    NSWorkspace.shared.open(storageDirectoryURL)
                                }
                                .buttonStyle(.bordered)

                                Button("Change Location") {
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
                Label("General", systemImage: "gearshape")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingsSection(
                        title: "Application",
                        subtitle: "Version and author."
                    ) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.2.0 (2028)")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Author")
                            Spacer()
                            Text("Yifan Gong")
                                .foregroundStyle(.secondary)
                        }
                    }

                    settingsSection(
                        title: "Project",
                        subtitle: "Source repository."
                    ) {
                        Link(
                            "github.com/CouldfulRial/FlexFocus",
                            destination: URL(string: "https://github.com/CouldfulRial/FlexFocus")!
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 520, height: 500)
        .padding(.top, 8)
        .alert("Clear all history?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                NotificationCenter.default.post(name: .clearAllHistoryRequested, object: nil)
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .storageDirectoryDidChange)) { _ in
            storageDirectoryURL = StoragePathManager.shared.currentDataDirectoryURL
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
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

    private func changeStorageLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = storageDirectoryURL
        panel.prompt = "Select"

        if panel.runModal() == .OK, let selected = panel.url {
            StoragePathManager.shared.updateDataDirectory(to: selected)
            storageDirectoryURL = StoragePathManager.shared.currentDataDirectoryURL
        }
    }
}
