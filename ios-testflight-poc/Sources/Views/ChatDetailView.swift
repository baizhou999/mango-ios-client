import SwiftUI
import Foundation

struct ChatDetailView: View {
    let chat: Chat
    @EnvironmentObject private var state: AppState
    @State private var messages: [Message]
    @State private var draft = ""
    @State private var pendingText: String?
    @State private var showConfirm = false

    init(chat: Chat) {
        self.chat = chat
        _messages = State(initialValue: Message.samples(for: chat))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(16)
            }
            .background(Theme.surface)

            composer
        }
        .navigationTitle(chat.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("发送前确认", isPresented: $showConfirm, titleVisibility: .visible) {
            Button("发送") {
                if let text = pendingText {
                    append(text)
                }
                pendingText = nil
            }
            Button("取消", role: .cancel) {
                pendingText = nil
            }
        } message: {
            Text(pendingText ?? "")
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("输入消息", text: $draft)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(Theme.accent)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(12)
        .background(Theme.surface)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if state.settings.confirmBeforeSend {
            pendingText = text
            showConfirm = true
        } else {
            append(text)
        }
    }

    private func append(_ text: String) {
        messages.append(Message(text: text, isOutgoing: true, time: "刚刚"))
        draft = ""
    }
}

private struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isOutgoing {
                Spacer(minLength: 48)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .foregroundColor(message.isOutgoing ? Theme.outgoingText : Theme.incomingText)
                Text(message.time)
                    .font(.caption2)
                    .foregroundColor(message.isOutgoing ? Color.white.opacity(0.75) : Color.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(message.isOutgoing ? Theme.accent : Theme.incomingBubble)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !message.isOutgoing {
                Spacer(minLength: 48)
            }
        }
    }
}
