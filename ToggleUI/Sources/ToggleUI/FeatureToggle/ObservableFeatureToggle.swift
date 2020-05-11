import Foundation
import Combine

/// Feature toggle property wrapper that accepts toggle provider as constructor parameter
public typealias ObservableFeatureToggle<T: Hashable> = ProviderResolvingObservableFeatureToggle<T, EmptyToggleProviderResolving>

/// Feature toggle that provides observable value
@propertyWrapper @dynamicMemberLookup
public struct ProviderResolvingObservableFeatureToggle<T: Hashable, P: ToggleProviderResolving> {
    public var toggle: ProviderResolvingFeatureToggle<T, P>

    /// Publisher that publishes effective value of the feature toggle or its default value if computing effective value throws an error
    public let wrappedValue: AnyPublisher<T, Never>

    /// Feature toggle itself
    /// - Note: Setter only updates default value of the feature toggle, should be only used in `WithDefaults` implementation
    public var projectedValue: Self {
        get { self }
        set { self.toggle.defaultValue = newValue.toggle.defaultValue }
    }

    public init(toggle: ProviderResolvingFeatureToggle<T, P>) {
        self.toggle = toggle
        self.wrappedValue = toggle.provider.effectiveValue(for: toggle)
            .map { (try? $0.get()) ?? toggle.defaultValue }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public var defaultValue: T {
        get { toggle.defaultValue }
        set { self.toggle.defaultValue = newValue }
    }

    public subscript<U>(dynamicMember keyPath: KeyPath<ProviderResolvingFeatureToggle<T, P>, U>) -> U {
        toggle[keyPath: keyPath]
    }

    /// Overrides value for the feature toggle key by setting it with `override` provider, should be only used in `WithDefaults` implementation
    public mutating func setValue(_ value: T) {
        toggle.setValue(value)
    }
}

extension ProviderResolvingObservableFeatureToggle where P == EmptyToggleProviderResolving {
    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping FeatureToggle<T>.Getter,
        provider: ToggleProvider
    ) {
        self.init(toggle: FeatureToggle(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            get: get,
            provider: provider
        ))
    }

    public init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping FeatureToggle<T>.Getter,
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

extension ProviderResolvingObservableFeatureToggle {
    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping ProviderResolvingFeatureToggle<T, P>.Getter
    ) {
        self.init(toggle: ProviderResolvingFeatureToggle(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            get: get
        ))
    }

    public init<Key: RawRepresentable>(
        key: Key,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugValues: [AnyHashable] = [],
        debugDescription: String = "",
        get: @escaping ProviderResolvingFeatureToggle<T, P>.Getter
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

public extension ProviderResolvingObservableFeatureToggle where P == EmptyToggleProviderResolving, T: ExpressibleByBooleanLiteral, T.BooleanLiteralType == Bool {
    init(
        key: String,
        defaultValue: T = false,
        userInfo: [String: Any] = [:],
        debugDescription: String = "",
        provider: ToggleProvider
    ) {
        self.init(toggle: FeatureToggle(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugDescription: debugDescription,
            provider: provider
        ))
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

public extension ProviderResolvingObservableFeatureToggle where T: ExpressibleByBooleanLiteral, T.BooleanLiteralType == Bool {
    init(
        key: String,
        defaultValue: T = false,
        userInfo: [String: Any] = [:],
        debugDescription: String = ""
    ) {
        self.init(toggle: ProviderResolvingFeatureToggle(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugDescription: debugDescription
        ))
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

public extension ProviderResolvingObservableFeatureToggle where P == EmptyToggleProviderResolving, T: ExpressibleByStringLiteral, T.StringLiteralType == String {
    init(
        key: String,
        defaultValue: T = "",
        userInfo: [String: Any] = [:],
        debugValues: [T] = [],
        debugDescription: String = "",
        provider: ToggleProvider
    ) {
        self.init(toggle: FeatureToggle(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            provider: provider
        ))
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

public extension ProviderResolvingObservableFeatureToggle where T: ExpressibleByStringLiteral, T.StringLiteralType == String {
    init(
        key: String,
        defaultValue: T = "",
        userInfo: [String: Any] = [:],
        debugValues: [T] = [],
        debugDescription: String = ""
    ) {
        self.init(toggle: ProviderResolvingFeatureToggle(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription
        ))
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

extension ProviderResolvingObservableFeatureToggle where P == EmptyToggleProviderResolving, T: RawRepresentable & CaseIterable, T.RawValue == String {
    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugDescription: String = "",
        provider: ToggleProvider
    ) {
        self.init(toggle: FeatureToggle(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: Array(T.allCases).map { $0.rawValue },
            debugDescription: debugDescription,
            get: { try T(rawValue: $0.decode()) ?? defaultValue },
            provider: provider
        ))
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

extension ProviderResolvingObservableFeatureToggle where T: RawRepresentable & CaseIterable, T.RawValue == String {
    public init(
        key: String,
        defaultValue: T,
        userInfo: [String: Any] = [:],
        debugDescription: String = ""
    ) {
        self.init(toggle: ProviderResolvingFeatureToggle(
            key: key,
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: Array(T.allCases).map { $0.rawValue },
            debugDescription: debugDescription,
            get: { try T(rawValue: $0.decode()) ?? defaultValue }
        ))
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
