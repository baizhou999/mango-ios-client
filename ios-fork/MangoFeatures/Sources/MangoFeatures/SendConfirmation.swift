import Foundation

public enum SendContext: String, Codable, CaseIterable {
    case privateChat
    case group
    case channel
    case savedMessages
}

public struct SendConfirmationSettings: Codable, Equatable {
    public var enabled: Bool
    public var confirmInGroups: Bool
    public var confirmInChannels: Bool
    public var confirmLongMessages: Bool
    public var longMessageThreshold: Int

    public init(
        enabled: Bool = true,
        confirmInGroups: Bool = true,
        confirmInChannels: Bool = true,
        confirmLongMessages: Bool = false,
        longMessageThreshold: Int = 200
    ) {
        self.enabled = enabled
        self.confirmInGroups = confirmInGroups
        self.confirmInChannels = confirmInChannels
        self.confirmLongMessages = confirmLongMessages
        self.longMessageThreshold = longMessageThreshold
    }
}

public struct SendConfirmationPolicy {
    public init() {}

    public func shouldConfirm(
        text: String,
        context: SendContext,
        settings: SendConfirmationSettings
    ) -> Bool {
        guard settings.enabled else { return false }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if settings.confirmLongMessages && trimmed.count >= settings.longMessageThreshold {
            return true
        }

        switch context {
        case .group:
            return settings.confirmInGroups
        case .channel:
            return settings.confirmInChannels
        case .privateChat, .savedMessages:
            return true
        }
    }
}
