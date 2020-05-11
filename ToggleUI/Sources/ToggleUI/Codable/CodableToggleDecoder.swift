/// Uses `Decoder` to access values. Typically used with CodableToggleProvider.
public struct CodableToggleDecoder: ToggleDecoder {
    public var key: String
    /// Decoder to decode values with
    public let decoder: Decoder

    public init(key: String, decoder: Decoder) {
        self.key = key
        self.decoder = decoder
    }

    public func decode() throws -> Bool {
        let container = try decoder.container(keyedBy: CodingKeyPath.self)
        return try container.decode(Bool.self, forKeyPath: CodingKeyPath(key))
    }

    public func decode() throws -> String {
        let container = try decoder.container(keyedBy: CodingKeyPath.self)
        return try container.decode(String.self, forKeyPath: CodingKeyPath(key))
    }

    public func decode(key: String) throws -> Bool {
        let container = try decoder.container(keyedBy: CodingKeyPath.self)
        let nestedKey = CodingKeyPath(keys: self.key, key)
        return try container.decode(Bool.self, forKeyPath: nestedKey)
    }

    public func decode(key: String) throws -> String {
        let container = try decoder.container(keyedBy: CodingKeyPath.self)
        let nestedKey = CodingKeyPath(keys: self.key, key)
        return try container.decode(String.self, forKeyPath: nestedKey)
    }
}

/// Coding key that can represent a key path using `.` as a components separator
public struct CodingKeyPath: CodingKey, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    public var intValue: Int?
    public var stringValue: String

    public init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = Int(stringValue)
    }

    public init(stringLiteral value: String) {
        self.init(stringValue: value)!
    }

    public init(_ value: String) {
        self.init(stringValue: value)!
    }

    public init(integerLiteral value: Int) {
        self.init(intValue: value)!
    }

    public init(keys: String...) {
        self.init(keys: keys)
    }

    public init(keys: [String]) {
        self.init(keys.joined())
    }

    /// Returns the first key path component and the rest of the key path
    public var head: (CodingKeyPath, CodingKeyPath) {
        var keyPath = stringValue.components(separatedBy: ".")
        return (CodingKeyPath(keyPath.removeFirst()), CodingKeyPath(keys: keyPath))
    }

    public var isEmpty: Bool {
        stringValue.isEmpty
    }

    public var path: [String] {
        stringValue.components(separatedBy: ".")
    }
}

struct EmptyCodable: Codable {}

extension UnkeyedDecodingContainer {
    /// Gets nested unkeyed container shifted to the index (for array-in-array)
    mutating func nestedUnkeyedContainer(at index: Int) throws -> UnkeyedDecodingContainer {
        var unkeyedContainer = try nestedUnkeyedContainer()
        try unkeyedContainer.advance(to: index)
        return unkeyedContainer
    }

    mutating func advance(to index: Int) throws {
        for _ in 0..<index {
            _ = try self.decode(EmptyCodable.self)
        }
    }
}

extension KeyedDecodingContainer {
    /// Gets nested unkeyed container shifted to the index (for array-in-dict)
    func nestedUnkeyedContainer(forKey key: Key, at index: Int) throws -> UnkeyedDecodingContainer {
        var unkeyedContainer = try nestedUnkeyedContainer(forKey: key)
        try unkeyedContainer.advance(to: index)
        return unkeyedContainer
    }
}

public extension KeyedDecodingContainer where Key == CodingKeyPath {
    func decode<T: Decodable>(_ type: T.Type, forKeyPath key: CodingKeyPath) throws -> T {
        var keyedContainer: Self? = self
        var unkeyedContainer: UnkeyedDecodingContainer? = nil

        var (key, keyPath) = key.head

        while !keyPath.isEmpty {
            if let index = key.intValue {
                unkeyedContainer = try keyedContainer?.nestedUnkeyedContainer(forKey: key, at: index)
                    ?? unkeyedContainer?.nestedUnkeyedContainer(at: index)
                keyedContainer = nil
            } else {
                keyedContainer = try keyedContainer?.nestedContainer(keyedBy: CodingKeyPath.self, forKey: key)
                    ?? unkeyedContainer?.nestedContainer(keyedBy: CodingKeyPath.self)
                unkeyedContainer = nil
            }
            (key, keyPath) = keyPath.head
        }

        if let c = keyedContainer {
            return try c.decode(T.self, forKey: key)
        } else if var c = unkeyedContainer {
            return try c.decode(T.self)
        } else {
            fatalError("Should never happen")
        }
    }
}

extension Array where Element == String {
    func joined() -> String {
        self.joined(separator: ".")
    }
}
