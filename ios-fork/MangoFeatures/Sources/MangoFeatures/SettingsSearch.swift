import Foundation

public struct SettingsSearchItem: Equatable, Identifiable {
    public let id: String
    public var title: String
    public var keywords: [String]
    public var path: [String]

    public init(id: String, title: String, keywords: [String] = [], path: [String] = []) {
        self.id = id
        self.title = title
        self.keywords = keywords
        self.path = path
    }
}

public struct SettingsSearchIndex {
    private let items: [SettingsSearchItem]

    public init(items: [SettingsSearchItem]) {
        self.items = items
    }

    public func search(_ query: String, limit: Int = 20) -> [SettingsSearchItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let needle = fold(trimmed)
        let scored = items.compactMap { item -> (item: SettingsSearchItem, score: Int)? in
            let title = fold(item.title)

            if title == needle {
                return (item, 100)
            }
            if title.hasPrefix(needle) {
                return (item, 80)
            }
            if title.contains(needle) {
                return (item, 60)
            }
            if item.keywords.contains(where: { fold($0).contains(needle) }) {
                return (item, 40)
            }
            if item.path.contains(where: { fold($0).contains(needle) }) {
                return (item, 20)
            }
            return nil
        }

        return scored
            .sorted { left, right in
                if left.score != right.score {
                    return left.score > right.score
                }
                return left.item.title.localizedStandardCompare(right.item.title) == .orderedAscending
            }
            .prefix(limit)
            .map(\.item)
    }

    private func fold(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "zh_Hans_CN"))
    }
}
