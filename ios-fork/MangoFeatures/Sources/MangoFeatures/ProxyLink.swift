import Foundation

public struct ProxyLink: Codable, Equatable {
    public enum Kind: String, Codable {
        case mtproto
        case socks5
    }

    public let kind: Kind
    public let server: String
    public let port: Int
    public let secret: String?
    public let username: String?
    public let password: String?

    public init(
        kind: Kind,
        server: String,
        port: Int,
        secret: String? = nil,
        username: String? = nil,
        password: String? = nil
    ) {
        self.kind = kind
        self.server = server
        self.port = port
        self.secret = secret
        self.username = username
        self.password = password
    }
}

public enum ProxyLinkError: Error, Equatable, LocalizedError {
    case unsupportedScheme
    case missingServer
    case invalidPort
    case missingSecret

    public var errorDescription: String? {
        switch self {
        case .unsupportedScheme:
            return "只支持 tg://proxy、tg://socks 和 t.me 的代理链接"
        case .missingServer:
            return "代理链接缺少 server"
        case .invalidPort:
            return "代理链接端口无效"
        case .missingSecret:
            return "MTProto 代理链接缺少 secret"
        }
    }
}

public struct ProxyLinkParser {
    public init() {}

    public func parse(_ raw: String) throws -> ProxyLink {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased() else {
            throw ProxyLinkError.unsupportedScheme
        }

        let host = components.host?.lowercased() ?? ""
        let path = components.path

        let kind: ProxyLink.Kind
        switch (scheme, host, path) {
        case ("tg", "proxy", _), ("https", "t.me", "/proxy"), ("http", "t.me", "/proxy"):
            kind = .mtproto
        case ("tg", "socks", _), ("https", "t.me", "/socks"), ("http", "t.me", "/socks"):
            kind = .socks5
        default:
            throw ProxyLinkError.unsupportedScheme
        }

        let query = Dictionary(
            (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            },
            uniquingKeysWith: { first, _ in first }
        )

        guard let server = query["server"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !server.isEmpty else {
            throw ProxyLinkError.missingServer
        }

        guard let rawPort = query["port"], let port = Int(rawPort), (1...65535).contains(port) else {
            throw ProxyLinkError.invalidPort
        }

        switch kind {
        case .mtproto:
            guard let secret = query["secret"], !secret.isEmpty else {
                throw ProxyLinkError.missingSecret
            }
            return ProxyLink(kind: .mtproto, server: server, port: port, secret: secret)
        case .socks5:
            return ProxyLink(
                kind: .socks5,
                server: server,
                port: port,
                username: query["user"],
                password: query["pass"]
            )
        }
    }
}
