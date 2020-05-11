public protocol ToggleDecoder {
    /// A root key for this decoder to decode value from
    var key: String { get set }

    /// Decode  boolean value from a root key of this decoder
    func decode() throws -> Bool
    /// Decode string value from a root key of this decoder
    func decode() throws -> String

    /// Decode boolean value from a nested key
    func decode(key: String) throws -> Bool
    /// Decode string value from a nested key
    func decode(key: String) throws -> String
}

extension ToggleDecoder {
    public func decode<T: LosslessStringConvertible>(key: String) throws -> T {
        let value: String = try decode(key: key)
        guard let converted = T(value) else {
            throw FeatureToggleDecodingError.typeMismatch(key: key, type: type(of: value), expected: T.self)
        }
        return converted
    }
}

public enum FeatureToggleDecodingError: Error {
    case keyNotFound(key: String)
    case typeMismatch(key: String, type: Any.Type, expected: Any.Type)
}
