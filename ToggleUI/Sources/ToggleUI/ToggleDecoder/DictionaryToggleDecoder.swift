import Foundation

/// Decoder that decodes values from a dictionary
public struct DictionaryToggleDecoder: ToggleDecoder {
    public let values: [String: Any]
    public var key: String

    public init(values: [String: Any], key: String) {
        self.values = values
        self.key = key
    }

    public func decode() throws -> Bool {
        try decode(key: "")
    }

    public func decode() throws -> String {
        try decode(key: "")
    }

    public func decode() throws -> Int {
        try decode(key: "")
    }

    public func decode() throws -> Float {
        try decode(key: "")
    }

    public func decode(key: String) throws -> Bool {
        let key = [self.key, key].filter { !$0.isEmpty }.joined()
        let value = try read(values: values, key: key)

        if let bool = value as? Bool {
            return bool
        } else if let string = value as? String {
            switch string.lowercased() {
            case "true", "yes", "1":
                return true
            default:
                return false
            }
        } else {
            throw FeatureToggleDecodingError.typeMismatch(key: key, type: type(of: value), expected: Bool.self)
        }
    }

    public func decode(key: String) throws -> String {
        let key = [self.key, key].filter { !$0.isEmpty }.joined()
        let value = try read(values: values, key: key)

        guard let string = value as? String else {
            throw FeatureToggleDecodingError.typeMismatch(
                key: key,
                type: type(of: value),
                expected: String.self
            )
        }
        return string
    }
}
