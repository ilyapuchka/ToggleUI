/// Feature toggle property wrapper. Accepts toggle provider as constructor parameter
public typealias FeatureToggle<T: Hashable> = ProviderResolvingFeatureToggle<T, EmptyToggleProviderResolving>

/// Feature toggle property wrapper. Accepts toggle provider as a generic type parameter
@propertyWrapper
public struct ProviderResolvingFeatureToggle<T: Hashable, P: ToggleProviderResolving> {
    public let key: String
    public var defaultValue: T
    public let userInfo: [String: Any]

    /// Effective toggle value provider
    public let provider: ToggleProvider
    /// Shorthand for `provider.override`
    public var override: ToggleProvider & ToggleOverriding { provider.override }

    public typealias Getter = (_ decoder: ToggleDecoder) throws -> T
    public let get: Getter

    /// Predefined toggle values for debug purposes that can be selected in DebugView
    public let debugValues: [AnyHashable]
    /// Toggle description for display in DebugView
    public let debugDescription: String

    /// Effective value of the feature toggle or its default value if computing effective value throws an error
    public var wrappedValue: T {
        (try? provider.effectiveValue(for: self))
            ?? defaultValue
    }

    /// Feature toggle itself
    /// - Note: Setter only updates default value of the feature toggle, should be only used in `WithDefaults` implementation
    public var projectedValue: Self {
        get { self }
        set { self.defaultValue = newValue.defaultValue }
    }

    /// Overrides value for the feature toggle key by setting it with `override` provider, should be only used in `WithDefaults` implementation
    public mutating func setValue(_ value: T) {
        override.setValue(value, forKey: key)
    }
}

extension ProviderResolvingFeatureToggle where P == EmptyToggleProviderResolving {
    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping Getter,
        provider: ToggleProvider
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userInfo = userInfo
        self.debugValues = debugValues
        self.debugDescription = debugDescription
        self.get = get
        self.provider = provider
    }

    public init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping Getter,
        provider: ToggleProvider
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            get: get,
            provider: provider
        )
    }
}

extension ProviderResolvingFeatureToggle {
    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping Getter
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userInfo = userInfo
        self.debugValues = debugValues
        self.debugDescription = debugDescription
        self.get = get
        self.provider = P.makeProvider()
    }

    public init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping Getter
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
}

public extension ProviderResolvingFeatureToggle where P == EmptyToggleProviderResolving, T: ExpressibleByBooleanLiteral, T.BooleanLiteralType == Bool {
    init(
        key: String,
        defaultValue: T = false,
        userInfo: [String: Any] = [:],
        debugDescription: String = "",
        provider: ToggleProvider
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugDescription: debugDescription,
            get: { try T(booleanLiteral: $0.decode()) },
            provider: provider
        )
    }

    init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T = false,
        userInfo: [String: Any] = [:],
        debugDescription: String = "",
        provider: ToggleProvider
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugDescription: debugDescription,
            provider: provider
        )
    }
}

public extension ProviderResolvingFeatureToggle where T: ExpressibleByBooleanLiteral, T.BooleanLiteralType == Bool {
    init(
        key: String,
        defaultValue: T = false,
        userInfo: [String: Any] = [:],
        debugDescription: String = ""
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugDescription: debugDescription,
            get: { try T(booleanLiteral: $0.decode()) }
        )
    }

    init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T = false,
        userInfo: [String: Any] = [:],
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

public extension ProviderResolvingFeatureToggle where P == EmptyToggleProviderResolving, T: ExpressibleByStringLiteral, T.StringLiteralType == String {
    init(
        key: String,
        defaultValue: T = "",
        userInfo: [String: Any] = [:],
        debugValues: [T] = [],
        debugDescription: String = "",
        provider: ToggleProvider
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            get: { try T(stringLiteral: $0.decode()) },
            provider: provider
        )
    }

    init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T = "",
        userInfo: [String: Any] = [:],
        debugValues: [T] = [],
        debugDescription: String = "",
        provider: ToggleProvider
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            provider: provider
        )
    }
}

public extension ProviderResolvingFeatureToggle where T: ExpressibleByStringLiteral, T.StringLiteralType == String {
    init(
        key: String,
        defaultValue: T = "",
        userInfo: [String: Any] = [:],
        debugValues: [T] = [],
        debugDescription: String = ""
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            get: { try T(stringLiteral: $0.decode()) }
        )
    }

    init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T = "",
        userInfo: [String: Any] = [:],
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

extension ProviderResolvingFeatureToggle where P == EmptyToggleProviderResolving, T: RawRepresentable & CaseIterable, T.RawValue == String {
    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugDescription: String = "",
        provider: ToggleProvider
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: Array(T.allCases).map { $0.rawValue },
            debugDescription: debugDescription,
            get: { try T(rawValue: $0.decode()) ?? defaultValue },
            provider: provider
        )
    }

    public init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugDescription: String = "",
        provider: ToggleProvider
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugDescription: debugDescription,
            provider: provider
        )
    }
}

extension ProviderResolvingFeatureToggle where T: RawRepresentable & CaseIterable, T.RawValue == String {
    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugDescription: String = ""
    ) {
        self.init(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: Array(T.allCases).map { $0.rawValue },
            debugDescription: debugDescription,
            get: { try T(rawValue: $0.decode()) ?? defaultValue }
        )
    }

    public init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T,
        userInfo: [String: Any] = [:],
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
