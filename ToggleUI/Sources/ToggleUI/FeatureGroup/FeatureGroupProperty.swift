@propertyWrapper
public class Reference<T> {
    public internal(set) var wrappedValue: T
    init(_ wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

protocol FeatureGroupPropertyType {
    func decode(from decoder: ToggleDecoder)
}

/// Feature group property defines a single property of a feature group that can be treated as a standalone feature toggle.
/// Feature group property uses provider of its feature group. Feature group property key is a key path which first component is a feature group key.
@propertyWrapper
public struct FeatureGroupProperty<T: Hashable>: FeatureGroupPropertyType, Hashable {
    public let key: String
    public var defaultValue: T
    public let userInfo: [String: AnyHashable]
    public let get: FeatureToggle<T>.Getter

    public let debugValues: [AnyHashable]
    public let debugDescription: String

    @Reference public internal(set) var wrappedValue: T

    /// Feature group property itself
    /// - Note: Setter only updates default value of the feature toggle, should be only used in `WithDefaults` implementation
    public var projectedValue: Self {
        get { self }
        set {
            self.defaultValue = newValue.defaultValue
            // projected value supposed to be changed only during init
            // this way we keep initial value consisten with default value
            // set in init or initWithDefaults
            self.wrappedValue = defaultValue
        }
    }

    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: AnyHashable] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping FeatureToggle<T>.Getter
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userInfo = userInfo
        self.debugValues = debugValues
        self.debugDescription = debugDescription
        self.get = get
        self._wrappedValue = Reference(defaultValue)
    }

    public init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T,
        userInfo: [String: AnyHashable] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping FeatureToggle<T>.Getter
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            get: get
        )
    }

    func decode(from decoder: ToggleDecoder) {
        wrappedValue = (try? get(decoder)) ?? wrappedValue
    }
    
    // Update value through binding
    func update(_ value: T) {
        wrappedValue = value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(wrappedValue)
        hasher.combine(defaultValue)
        hasher.combine(userInfo)
        hasher.combine(debugValues)
        hasher.combine(debugDescription)
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        guard lhs.key == rhs.key else { return false }
        guard lhs.wrappedValue == rhs.wrappedValue else { return false }
        guard lhs.defaultValue == rhs.defaultValue else { return false }
        guard lhs.userInfo == rhs.userInfo else { return false }
        guard lhs.debugValues == rhs.debugValues else { return false }
        guard lhs.debugDescription == rhs.debugDescription else { return false }
        return true
    }
}

public extension FeatureGroupProperty where T: ExpressibleByBooleanLiteral, T.BooleanLiteralType == Bool {
    init(
        key: String,
        defaultValue: T = false,
        userInfo: [String: AnyHashable] = [:],
        debugDescription: String = ""
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: [],
            debugDescription: debugDescription,
            get: { try T(booleanLiteral: $0.decode(key: key)) }
        )
    }

    init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T = false,
        userInfo: [String: AnyHashable] = [:],
        debugDescription: String = ""
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugDescription: debugDescription
        )
    }
}

public extension FeatureGroupProperty where T: ExpressibleByStringLiteral, T.StringLiteralType == String {
    init(
        key: String,
        defaultValue: T = "",
        userInfo: [String: AnyHashable] = [:],
        debugValues: [T] = [],
        debugDescription: String = ""
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            get: { try T(stringLiteral: $0.decode(key: key)) }
        )
    }

    init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T = "",
        userInfo: [String: AnyHashable] = [:],
        debugValues: [T] = [],
        debugDescription: String = ""
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription
        )
    }
}

extension FeatureGroupProperty where T: RawRepresentable & CaseIterable, T.RawValue == String {
    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: AnyHashable] = [:],
        debugDescription: String = ""
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: Array(T.allCases).map { $0.rawValue },
            debugDescription: debugDescription,
            get: { try T(rawValue: $0.decode(key: key)) ?? defaultValue }
        )
    }

    public init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T,
        userInfo: [String: AnyHashable] = [:],
        debugDescription: String = ""
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugDescription: debugDescription
        )
    }
}

extension FeatureGroupProperty where T: FeatureGroupDecodable {
    public init(
        key: String,
        userInfo: [String: AnyHashable] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = ""
    ) {
        self.init(
            key: key,
            defaultValue: T(),
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            get: { decoder in
                var decoder = decoder
                decoder.key = [decoder.key, key].joined()
                return try T(decoder: decoder)
            }
        )
    }

    public init<Key: RawRepresentable>(
        key: Key,
        userInfo: [String: AnyHashable] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = ""
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription
        )
    }
}
