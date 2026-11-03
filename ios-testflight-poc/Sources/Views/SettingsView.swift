import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("消息增强")) {
                    Toggle("关键词提醒", isOn: $state.settings.keywordAlertsEnabled)
                    Toggle("发送前确认", isOn: $state.settings.confirmBeforeSend)
                    Toggle("媒体自动清理", isOn: $state.settings.autoCleanMedia)
                }

                Section(header: Text("网络")) {
                    NavigationLink(
                        "代理与连接",
                        destination: PlaceholderDetail(
                            title: "代理与连接",
                            detail: "接入 Telegram 后，这里管理 MTProxy 与连接策略。"
                        )
                    )
                }

                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(AppInfo.versionText)
                            .foregroundColor(.secondary)
                    }
                    Button("退出登录", role: .destructive) {
                        state.signOut()
                    }
                }
            }
            .navigationTitle("设置")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PlaceholderDetail: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
