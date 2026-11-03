import Foundation
import Combine

final class AppState: ObservableObject {
    enum Route {
        case login
        case main
    }

    @Published var route: Route = .login
    @Published var chats: [Chat] = Chat.samples
    @Published var settings = MangoSettings()

    func signIn(phone: String) {
        route = .main
    }

    func signOut() {
        route = .login
    }
}

struct MangoSettings {
    var keywordAlertsEnabled = true
    var confirmBeforeSend = true
    var autoCleanMedia = false
}
