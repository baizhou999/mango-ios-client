import Foundation

struct Chat: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var lastMessage: String
    var timestamp: String
    var unreadCount: Int = 0
    var accentIndex: Int = 0
}

extension Chat {
    static let samples: [Chat] = [
        Chat(title: "芒果产品组", lastMessage: "今晚 8 点发版，记得看群公告", timestamp: "21:32", unreadCount: 3),
        Chat(title: "阿哲", lastMessage: "代理节点我测过了，可用", timestamp: "20:41", accentIndex: 1),
        Chat(title: "文件传输助手", lastMessage: "mango-ios-notes.pdf", timestamp: "18:05", accentIndex: 2),
        Chat(title: "出海交流群", lastMessage: "新版本的关键词提醒挺好用", timestamp: "16:20", unreadCount: 12, accentIndex: 3),
        Chat(title: "小林", lastMessage: "收到，明天给你截图", timestamp: "昨天", accentIndex: 4)
    ]
}

struct Message: Identifiable {
    let id = UUID()
    var text: String
    var isOutgoing: Bool
    var time: String
}

extension Message {
    static func samples(for chat: Chat) -> [Message] {
        [
            Message(text: "这是 \(chat.title) 的演示会话。", isOutgoing: false, time: "20:10"),
            Message(text: "当前 UI 跑在本地数据上，Telegram 接入层还没接。", isOutgoing: false, time: "20:11"),
            Message(text: "接入完成后，这里就是真实消息。", isOutgoing: true, time: "20:12")
        ]
    }
}
