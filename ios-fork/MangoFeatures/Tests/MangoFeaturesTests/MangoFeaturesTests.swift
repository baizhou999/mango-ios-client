import XCTest
@testable import MangoFeatures

final class KeywordMatcherTests: XCTestCase {
    private let matcher = KeywordMatcher()

    func testCaseInsensitiveMatch() {
        let rule = KeywordAlertRule(keyword: "Urgent")
        XCTAssertEqual(matcher.firstMatch(in: "this is urgent", rules: [rule])?.id, rule.id)
    }

    func testCaseSensitiveMiss() {
        let rule = KeywordAlertRule(keyword: "Urgent", caseSensitive: true)
        XCTAssertNil(matcher.firstMatch(in: "this is urgent", rules: [rule]))
    }

    func testWholeWordDoesNotMatchSubstring() {
        let rule = KeywordAlertRule(keyword: "cat", matchWholeWord: true)
        XCTAssertNil(matcher.firstMatch(in: "concatenate", rules: [rule]))
        XCTAssertEqual(matcher.firstMatch(in: "a cat is here", rules: [rule])?.id, rule.id)
    }

    func testChineseSubstringMatchesDespiteWholeWord() {
        let rule = KeywordAlertRule(keyword: "发版", matchWholeWord: true)
        XCTAssertEqual(matcher.firstMatch(in: "今晚发版", rules: [rule])?.id, rule.id)
    }

    func testDisabledRuleIsSkipped() {
        let rule = KeywordAlertRule(keyword: "紧急", enabled: false)
        XCTAssertNil(matcher.firstMatch(in: "紧急通知", rules: [rule]))
    }
}

final class SendConfirmationPolicyTests: XCTestCase {
    private let policy = SendConfirmationPolicy()

    func testDisabledNeverConfirms() {
        var settings = SendConfirmationSettings()
        settings.enabled = false
        XCTAssertFalse(policy.shouldConfirm(text: "hello", context: .group, settings: settings))
    }

    func testGroupOptOut() {
        var settings = SendConfirmationSettings()
        settings.confirmInGroups = false
        XCTAssertFalse(policy.shouldConfirm(text: "hello", context: .group, settings: settings))
    }

    func testLongMessageOverridesGroupOptOut() {
        var settings = SendConfirmationSettings()
        settings.confirmInGroups = false
        settings.confirmLongMessages = true
        settings.longMessageThreshold = 10
        XCTAssertTrue(
            policy.shouldConfirm(
                text: String(repeating: "a", count: 10),
                context: .group,
                settings: settings
            )
        )
    }

    func testEmptyTextNeverConfirms() {
        XCTAssertFalse(
            policy.shouldConfirm(
                text: "   ",
                context: .privateChat,
                settings: SendConfirmationSettings()
            )
        )
    }
}

final class MediaCleanupPlannerTests: XCTestCase {
    private let planner = MediaCleanupPlanner()
    private let now = Date(timeIntervalSince1970: 40 * 86400)

    private func item(
        _ id: String,
        daysAgo: Double,
        bytes: Int64 = 100,
        kept: Bool = false,
        kind: MediaKind = .photo
    ) -> MediaCacheItem {
        MediaCacheItem(
            id: id,
            kind: kind,
            byteCount: bytes,
            lastAccess: now.addingTimeInterval(-daysAgo * 86400),
            isKept: kept
        )
    }

    func testRemovesOnlyItemsOlderThanPolicy() {
        let items = [item("old", daysAgo: 40), item("recent", daysAgo: 5)]
        let plan = planner.plan(items: items, policy: MediaCleanupPolicy(maxAgeDays: 30), now: now)
        XCTAssertEqual(plan.items.map(\.id), ["old"])
        XCTAssertEqual(plan.reclaimableBytes, 100)
    }

    func testKeepsMarkedItems() {
        let items = [item("marked", daysAgo: 40, kept: true)]
        let plan = planner.plan(items: items, policy: MediaCleanupPolicy(maxAgeDays: 30), now: now)
        XCTAssertTrue(plan.items.isEmpty)
    }

    func testKindFilter() {
        let items = [
            item("photo", daysAgo: 40, kind: .photo),
            item("video", daysAgo: 40, kind: .video)
        ]
        let plan = planner.plan(
            items: items,
            policy: MediaCleanupPolicy(maxAgeDays: 30, kinds: [.video]),
            now: now
        )
        XCTAssertEqual(plan.items.map(\.id), ["video"])
    }

    func testByteBudgetRemovesOldestFirst() {
        let items = [
            item("a", daysAgo: 40, bytes: 100),
            item("b", daysAgo: 20, bytes: 100)
        ]
        let plan = planner.plan(
            items: items,
            policy: MediaCleanupPolicy(maxAgeDays: 30, maxTotalBytes: 100),
            now: now
        )
        XCTAssertEqual(plan.items.map(\.id), ["a"])
    }
}

final class ProxyLinkParserTests: XCTestCase {
    private let parser = ProxyLinkParser()

    func testTGProxyLink() throws {
        let link = try parser.parse("tg://proxy?server=1.2.3.4&port=443&secret=abcd")
        XCTAssertEqual(link.kind, .mtproto)
        XCTAssertEqual(link.server, "1.2.3.4")
        XCTAssertEqual(link.port, 443)
        XCTAssertEqual(link.secret, "abcd")
    }

    func testWebSocksLink() throws {
        let link = try parser.parse("https://t.me/socks?server=5.6.7.8&port=1080&user=u&pass=p")
        XCTAssertEqual(link.kind, .socks5)
        XCTAssertEqual(link.username, "u")
        XCTAssertEqual(link.password, "p")
    }

    func testInvalidPortThrows() {
        XCTAssertThrowsError(try parser.parse("tg://proxy?server=1.2.3.4&port=70000&secret=abcd")) { error in
            guard let error = error as? ProxyLinkError else {
                return XCTFail("unexpected error: \(error)")
            }
            XCTAssertEqual(error, .invalidPort)
        }
    }

    func testMissingSecretThrows() {
        XCTAssertThrowsError(try parser.parse("tg://proxy?server=1.2.3.4&port=443")) { error in
            guard let error = error as? ProxyLinkError else {
                return XCTFail("unexpected error: \(error)")
            }
            XCTAssertEqual(error, .missingSecret)
        }
    }
}

final class SettingsSearchIndexTests: XCTestCase {
    private let index = SettingsSearchIndex(items: [
        SettingsSearchItem(id: "proxy", title: "代理与连接", keywords: ["proxy", "MTProto"]),
        SettingsSearchItem(id: "keyword", title: "关键词提醒", keywords: ["alert"]),
        SettingsSearchItem(id: "media", title: "媒体自动清理", path: ["存储", "缓存"])
    ])

    func testExactTitleRanking() {
        XCTAssertEqual(index.search("代理与连接").first?.id, "proxy")
    }

    func testKeywordSearch() {
        XCTAssertEqual(index.search("mtproto").first?.id, "proxy")
    }

    func testPathSearch() {
        XCTAssertEqual(index.search("缓存").first?.id, "media")
    }

    func testEmptyQueryReturnsEmpty() {
        XCTAssertTrue(index.search("   ").isEmpty)
    }

    func testLimit() {
        XCTAssertEqual(index.search("a", limit: 1).count, 1)
    }
}

final class MangoFeatureStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testRoundTrip() throws {
        let store = MangoFeatureStore(fileURL: directory.appendingPathComponent("settings.json"))
        let settings = MangoFeatureSettings(
            keywordAlertsEnabled: true,
            keywordAlertRules: [KeywordAlertRule(keyword: "发版")],
            alertMutedChatsOnKeywordMatch: true,
            proxies: [ProxyLink(kind: .mtproto, server: "1.2.3.4", port: 443, secret: "abcd")]
        )

        try store.save(settings)
        XCTAssertEqual(store.load(), settings)
    }

    func testMissingFileReturnsDefaults() {
        let store = MangoFeatureStore(fileURL: directory.appendingPathComponent("missing.json"))
        XCTAssertEqual(store.load(), MangoFeatureSettings())
    }

    func testCorruptedFileReturnsDefaults() throws {
        let url = directory.appendingPathComponent("broken.json")
        try Data("not json".utf8).write(to: url)
        let store = MangoFeatureStore(fileURL: url)
        XCTAssertEqual(store.load(), MangoFeatureSettings())
    }
}

final class KeywordAlertResolverTests: XCTestCase {
    private let resolver = KeywordAlertResolver()

    private var settings: MangoFeatureSettings {
        MangoFeatureSettings(
            keywordAlertsEnabled: true,
            keywordAlertRules: [KeywordAlertRule(keyword: "紧急")],
            alertMutedChatsOnKeywordMatch: true
        )
    }

    func testBypassesMuteOnMatch() {
        XCTAssertTrue(
            resolver.shouldBypassMute(text: "紧急通知", isChatMuted: true, settings: settings)
        )
    }

    func testNoBypassWithoutMatch() {
        XCTAssertFalse(
            resolver.shouldBypassMute(text: "普通消息", isChatMuted: true, settings: settings)
        )
    }

    func testNoBypassForUnmutedChat() {
        XCTAssertFalse(
            resolver.shouldBypassMute(text: "紧急通知", isChatMuted: false, settings: settings)
        )
    }

    func testNoBypassWhenFeatureDisabled() {
        var disabled = settings
        disabled.keywordAlertsEnabled = false
        XCTAssertFalse(
            resolver.shouldBypassMute(text: "紧急通知", isChatMuted: true, settings: disabled)
        )
    }
}
