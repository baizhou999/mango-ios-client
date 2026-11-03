import Foundation

public enum MediaKind: String, Codable, CaseIterable {
    case photo
    case video
    case voice
    case document
    case sticker
    case other
}

public struct MediaCacheItem: Codable, Equatable, Identifiable {
    public let id: String
    public var kind: MediaKind
    public var byteCount: Int64
    public var lastAccess: Date
    public var isKept: Bool

    public init(id: String, kind: MediaKind, byteCount: Int64, lastAccess: Date, isKept: Bool = false) {
        self.id = id
        self.kind = kind
        self.byteCount = byteCount
        self.lastAccess = lastAccess
        self.isKept = isKept
    }
}

public struct MediaCleanupPolicy: Codable, Equatable {
    public var maxAgeDays: Int
    public var kinds: Set<MediaKind>
    public var keepMarkedItems: Bool
    public var maxTotalBytes: Int64?

    public init(
        maxAgeDays: Int = 30,
        kinds: Set<MediaKind> = Set(MediaKind.allCases),
        keepMarkedItems: Bool = true,
        maxTotalBytes: Int64? = nil
    ) {
        self.maxAgeDays = maxAgeDays
        self.kinds = kinds
        self.keepMarkedItems = keepMarkedItems
        self.maxTotalBytes = maxTotalBytes
    }
}

public struct MediaCleanupPlan: Equatable {
    public let items: [MediaCacheItem]

    public var reclaimableBytes: Int64 {
        items.reduce(Int64(0)) { $0 + $1.byteCount }
    }
}

public struct MediaCleanupPlanner {
    public init() {}

    public func plan(
        items: [MediaCacheItem],
        policy: MediaCleanupPolicy,
        now: Date = Date()
    ) -> MediaCleanupPlan {
        let cutoff = now.addingTimeInterval(-Double(policy.maxAgeDays) * 86400)

        var candidates = items.filter { item in
            guard policy.kinds.contains(item.kind) else { return false }
            if policy.keepMarkedItems && item.isKept { return false }
            return item.lastAccess < cutoff
        }

        if let maxTotalBytes = policy.maxTotalBytes {
            let total = items.reduce(Int64(0)) { $0 + $1.byteCount }
            var projected = total
            var selected: [MediaCacheItem] = []

            for item in candidates.sorted(by: { $0.lastAccess < $1.lastAccess }) {
                guard projected > maxTotalBytes else { break }
                selected.append(item)
                projected -= item.byteCount
            }
            candidates = selected
        }

        return MediaCleanupPlan(items: candidates.sorted { $0.lastAccess < $1.lastAccess })
    }
}
