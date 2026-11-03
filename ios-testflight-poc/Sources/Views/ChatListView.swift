import SwiftUI
import Foundation

struct ChatListView: View {
    @EnvironmentObject private var state: AppState
    @State private var query = ""

    private var chats: [Chat] {
        guard !query.isEmpty else { return state.chats }
        return state.chats.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.lastMessage.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationView {
            List(chats) { chat in
                NavigationLink(destination: ChatDetailView(chat: chat)) {
                    ChatRow(chat: chat)
                }
            }
            .listStyle(.plain)
            .navigationTitle(AppInfo.displayName)
            .searchable(text: $query, prompt: "搜索聊天")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ChatRow: View {
    let chat: Chat

    private var avatarColor: Color {
        let colors: [Color] = [Theme.accent, .blue, .green, .purple, .pink]
        return colors[chat.accentIndex % colors.count]
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.18))
                Text(String(chat.title.prefix(1)))
                    .font(.headline)
                    .foregroundColor(avatarColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(chat.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(chat.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(chat.timestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
