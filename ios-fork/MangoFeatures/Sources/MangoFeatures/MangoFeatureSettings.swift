import Foundation

public struct MangoFeatureSettings: Codable, Equatable {
    public var keywordAlertsEnabled: Bool
    public var keywordAlertRules: [KeywordAlertRule]
    public var alertMutedChatsOnKeywordMatch: Bool
    public var sendConfirmation: SendConfirmationSettings
    public var mediaCleanup: MediaCleanupPolicy
    public var proxies: [ProxyLink]

    public init(
        keywordAlertsEnabled: Bool = false,
        keywordAlertRules: [KeywordAlertRule] = [],
        alertMutedChatsOnKeywordMatch: Bool = false,
        sendConfirmation: SendConfirmationSettings = SendConfirmationSettings(),
        mediaCleanup: MediaCleanupPolicy = MediaCleanupPolicy(),
        proxies: [ProxyLink] = []
    ) {
        self.keywordAlertsEnabled = keywordAlertsEnabled
        self.keywordAlertRules = keywordAlertRules
        self.alertMutedChatsOnKeywordMatch = alertMutedChatsOnKeywordMatch
        self.sendConfirmation = sendConfirmation
        self.mediaCleanup = mediaCleanup
        self.proxies = proxies
    }
}

public final class MangoFeatureStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func defaultFileURL(fileManager: FileManager = .default) throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("MangoFeatures", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("settings.json")
    }

    public func load() -> MangoFeatureSettings {
        guard let data = try? Data(contentsOf: fileURL) else {
            return MangoFeatureSettings()
        }
        do {
            return try JSONDecoder().decode(MangoFeatureSettings.self, from: data)
        } catch {
            return MangoFeatureSettings()
        }
    }

    public func save(_ settings: MangoFeatureSettings) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}

public struct KeywordAlertResolver {
    private let matcher: KeywordMatcher

    public init(matcher: KeywordMatcher = KeywordMatcher()) {
        self.matcher = matcher
    }

    public func shouldBypassMute(
        text: String,
        isChatMuted: Bool,
        settings: MangoFeatureSettings
    ) -> Bool {
        guard settings.keywordAlertsEnabled else { return false }
        guard isChatMuted else { return false }
        guard settings.alertMutedChatsOnKeywordMatch else { return false }

        return matcher.firstMatch(in: text, rules: settings.keywordAlertRules) != nil
    }
}
