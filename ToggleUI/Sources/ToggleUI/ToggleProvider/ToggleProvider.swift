import Foundation
import Combine

/// Provides actual values for feature toggles
public protocol ToggleProvider {
    /// Name of this provider for display in DebugView
    var name: String { get }
    /// Provider of actual values, by default returns `self`
    var provider: ToggleProvider { get }
    /// Provider for override values, by default returns `DefaultToggleProvider`
    var override: ToggleProvider & ToggleOverriding { get }

    /// Performs necessary setup for this provider, i.e. initialising and configuring 3rd party services.
    /// Emits a void value and completes when setup is complete
    func setUp() -> AnyPublisher<Void, Error>
    /// Refreshes underlying source of values, i.e. by resetting any cache that this provider may maintain or reaching to remote service for up to date values.
    /// Emits a void value and completes when setup is complete
    func refresh() -> AnyPublisher<Void, Error>

    /// Perform necessary cleanup, i.e. discarding any data associated with the current user session
    func tearDown()

    func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) throws -> T
    func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<T, Error>, Never>
    func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) throws -> ToggleDecoder
    func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never>

    func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> T
    func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<T, Error>, Never>
    func decoder<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> ToggleDecoder
    func decoder<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never>
}

public extension ToggleProvider {
    var name: String { "\(type(of: self))" }

    var provider: ToggleProvider { self }
    var override: ToggleProvider & ToggleOverriding { DefaultToggleProvider() }

    func setUp() -> AnyPublisher<Void, Error> { Empty().eraseToAnyPublisher() }
    func refresh() -> AnyPublisher<Void, Error> { Empty().eraseToAnyPublisher() }

    func tearDown() {}

    func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        Result { try value(for: toggle) }.publisher
    }

    func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        Result { try value(for: group) }.publisher
    }

    func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never> {
        Result { try decoder(for: toggle) }.publisher
    }

    func decoder<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> ToggleDecoder {
        try FeatureGroupDecoder(
            key: group.toggle.key,
            providerDecoder: self.decoder(for: group.toggle),
            overrideDecoder: self.override.decoder(for: group.toggle)
        )
    }

    func decoder<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never> {
        Result { try decoder(for: group) }.publisher
    }

    func effectiveValue<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) throws -> T {
        try override.hasValue(for: toggle.key)
            ? override.value(for: toggle)
            : provider.value(for: toggle)
    }

    func effectiveValue<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        override.value(for: toggle).flatMap { [provider] (overrideValue) -> AnyPublisher<Result<T, Error>, Never> in
            overrideValue.isFailure
                ? provider.value(for: toggle)
                : Just(overrideValue).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }

    func effectiveValue<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> T {
        try group.toggle.get(decoder(for: group))
    }

    func effectiveValue<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        return Publishers.CombineLatest(
            decoder(for: group.toggle),
            override.decoder(for: group.toggle)
        ).map { (providerDecoder, overrideDecoder) -> Result<T, Error> in
            Result {
                switch (providerDecoder, overrideDecoder) {
                case let (.success(providerDecoder), .success(overrideDecoder)):
                    return FeatureGroupDecoder(
                        key: group.toggle.key,
                        providerDecoder: providerDecoder,
                        overrideDecoder: overrideDecoder
                    )
                case (.success(let decoder), .failure):
                    return decoder
                case (.failure, let .success(decoder)):
                    return decoder
                case (.failure(let error), .failure):
                    throw error
                }
            }.flatMap { decoder in
                Result {
                    try group.toggle.get(decoder)
                }
            }
        }.eraseToAnyPublisher()
    }
}

extension Result {
    var publisher: AnyPublisher<Self, Never> {
        Publishers.Sequence(sequence: [self]).eraseToAnyPublisher()
    }

    var isFailure: Bool {
        if case .failure = self { return true }
        else { return false }
    }
}

public protocol ToggleOverriding {
    func hasValue(for key: String) -> Bool
    func setValue(_ value: Any?, forKey key: String)
}

public struct OverridableToggleProvider: ToggleProvider, ToggleOverriding {
    public let provider: ToggleProvider
    public let override: ToggleOverriding & ToggleProvider

    public var name: String { provider.name }

    public init(
        provider: ToggleProvider,
        override: ToggleOverriding & ToggleProvider
    ) {
        self.provider = provider
        self.override = override
    }

    public func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) throws -> T where T : Hashable {
        try provider.value(for: toggle)
    }

    public func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> T {
        try provider.value(for: group)
    }

    public func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        provider.value(for: toggle)
    }

    public func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        provider.value(for: group)
    }

    public func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) throws -> ToggleDecoder {
        try provider.decoder(for: toggle)
    }

    public func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never> {
        provider.decoder(for: toggle)
    }

    public func decoder<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> ToggleDecoder {
        try provider.decoder(for: group)
    }

    public func decoder<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never> {
        provider.decoder(for: group)
    }

    public func hasValue(for key: String) -> Bool {
        override.hasValue(for: key)
    }

    public func setValue(_ value: Any?, forKey key: String) {
        override.setValue(value, forKey: key)
    }
}

/// A toggle provider that always returns default values and does noting on override
public struct DefaultToggleProvider: ToggleProvider, ToggleOverriding {
    public func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) throws -> T {
        toggle.defaultValue
    }

    public func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> T {
        group.toggle.defaultValue
    }

    public func hasValue(for key: String) -> Bool {
        false
    }

    public func setValue(_ value: Any?, forKey key: String) {}

    public func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> ToggleDecoder {
        DictionaryToggleDecoder(values: [:], key: toggle.key)
    }
}

public enum InMemoryProviderResolver: ToggleProviderResolving {
    public static var provider = InMemoryToggleProvider(values: [:])

    public static func makeProvider() -> ToggleProvider {
        provider
    }
}

public typealias InMemoryFeatureToggle<T: Hashable> = ProviderResolvingFeatureToggle<T, InMemoryProviderResolver>
public typealias InMemoryObservableFeatureToggle<T: Hashable> = ProviderResolvingObservableFeatureToggle<T, InMemoryProviderResolver>
public typealias InMemoryFeatureGroup<T: FeatureGroupDecodable> = ProviderResolvingFeatureGroup<T, InMemoryProviderResolver>
public typealias InMemoryObservableFeatureGroup<T: FeatureGroupDecodable> = ProviderResolvingObservableFeatureGroup<T, InMemoryProviderResolver>

/// A toggle provider that stores values in memory
public struct InMemoryToggleProvider: ToggleProvider {
    public var values: [String: Any]

    public init(values: [String: Any]) {
        self.values = values
    }

    public func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) throws -> T {
        try toggle.get(self.decoder(for: toggle))
    }

    public func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> T {
        try value(for: group.toggle)
    }

    public func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> ToggleDecoder {
        DictionaryToggleDecoder(values: values, key: toggle.key)
    }
}
