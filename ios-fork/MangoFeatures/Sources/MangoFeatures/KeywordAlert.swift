import Foundation

public struct KeywordAlertRule: Codable, Equatable, Identifiable {
    public let id: UUID
    public var keyword: String
    public var caseSensitive: Bool
    public var matchWholeWord: Bool
    public var enabled: Bool

    public init(
        id: UUID = UUID(),
        keyword: String,
        caseSensitive: Bool = false,
        matchWholeWord: Bool = false,
        enabled: Bool = true
    ) {
        self.id = id
        self.keyword = keyword
        self.caseSensitive = caseSensitive
        self.matchWholeWord = matchWholeWord
        self.enabled = enabled
    }
}

public struct KeywordMatcher {
    public init() {}

    public func firstMatch(in text: String, rules: [KeywordAlertRule]) -> KeywordAlertRule? {
        let foldedText = fold(text)

        for rule in rules where rule.enabled {
            let keyword = rule.keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !keyword.isEmpty else { continue }

            let haystack = rule.caseSensitive ? text : foldedText
            let needle = rule.caseSensitive ? keyword : fold(keyword)
            guard haystack.contains(needle) else { continue }

            if rule.matchWholeWord && !containsCJK(needle) && !matchesWholeWord(needle: needle, in: haystack) {
                continue
            }
            return rule
        }

        return nil
    }

    private func fold(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "zh_Hans_CN"))
    }

    private func containsCJK(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value) || (0x3400...0x4DBF).contains(scalar.value)
        }
    }

    private func matchesWholeWord(needle: String, in haystack: String) -> Bool {
        var searchRange = haystack.startIndex..<haystack.endIndex

        while let range = haystack.range(of: needle, options: [], range: searchRange) {
            let startOK = range.lowerBound == haystack.startIndex
                || !isWordCharacter(haystack[haystack.index(before: range.lowerBound)])
            let endOK = range.upperBound == haystack.endIndex
                || !isWordCharacter(haystack[range.upperBound])

            if startOK && endOK {
                return true
            }
            searchRange = range.upperBound..<haystack.endIndex
        }

        return false
    }

    private func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_"
    }
}
