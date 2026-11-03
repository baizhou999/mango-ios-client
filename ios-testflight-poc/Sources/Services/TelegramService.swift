import Foundation

protocol TelegramService {
    func requestCode(phoneNumber: String) async throws
    func signIn(code: String) async throws
    func send(text: String, to chat: Chat) async throws
}

enum TelegramServiceError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Telegram 接入层尚未配置"
        }
    }
}

struct PlaceholderTelegramService: TelegramService {
    func requestCode(phoneNumber: String) async throws {
        throw TelegramServiceError.notConfigured
    }

    func signIn(code: String) async throws {
        throw TelegramServiceError.notConfigured
    }

    func send(text: String, to chat: Chat) async throws {
        throw TelegramServiceError.notConfigured
    }
}
