import SwiftUI

struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        switch state.route {
        case .login:
            LoginView()
        case .main:
            MainView()
        }
    }
}

struct MainView: View {
    var body: some View {
        TabView {
            ChatListView()
                .tabItem {
                    Label("聊天", systemImage: "bubble.left.and.bubble.right")
                }
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
    }
}
