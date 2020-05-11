import Foundation
import Combine

/// Feature group property wrapper that accepts toggle provider as constructor parameter
public typealias ObservableFeatureGroup<T: FeatureGroupDecodable> = ProviderResolvingObservableFeatureGroup<T, EmptyToggleProviderResolving>

/// Feature group variant that provides observable value
@propertyWrapper @dynamicMemberLookup
public struct ProviderResolvingObservableFeatureGroup<T: FeatureGroupDecodable, P: ToggleProviderResolving> {
    public var group: ProviderResolvingFeatureGroup<T, P>

    /// Publisher that publishes effective value of the feature group or its default value if computing effective value throws an error
    public let wrappedValue: AnyPublisher<T, Never>

    /// Feature group itself
    /// - Note: Setter only updates default value of the backing feature toggle, should be only used in `WithDefaults` implementation
    public var projectedValue: Self {
        get { self }
        set { self.group.toggle.defaultValue = newValue.group.toggle.defaultValue }
    }

    public init(group: ProviderResolvingFeatureGroup<T, P>) {
        self.group = group
        self.wrappedValue = group.toggle.provider.effectiveValue(for: group)
            .map { (try? $0.get()) ?? group.toggle.defaultValue }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
        self.defaultValue = DefaultValueProxy(wrappedValue: group.toggle.defaultValue)
    }

    /// Proxy to set default value of feature group's properties
    ///
    /// Example:
    /// ```
    /// myFeatures.$myFeatureGroup.defaultValue.$featureProperty = <new default value>
    /// ```
    public var defaultValue: DefaultValueProxy<T> {
        willSet { group.toggle.defaultValue = newValue.wrappedValue }
    }

    @dynamicMemberLookup
    public struct DefaultValueProxy<T> {
        var wrappedValue: T

        public subscript<U>(dynamicMember keyPath: WritableKeyPath<T, FeatureGroupProperty<U>>) -> U {
            get { wrappedValue[keyPath: keyPath].defaultValue }
            set { wrappedValue[keyPath: keyPath].defaultValue = newValue }
        }
    }

    public subscript<U>(dynamicMember keyPath: KeyPath<ProviderResolvingFeatureToggle<T, P>, U>) -> U {
        group.toggle[keyPath: keyPath]
    }

    @dynamicMemberLookup
    public struct PropertyProxy<T: Hashable> {
        var property: FeatureGroupProperty<T>

        /// Overrides value for the feature property key by setting it with `override` provider, should be only used in `WithDefaults` implementation
        ///
        /// Example:
        /// ```
        /// myFeatures.$myFeatureGroup.$featureProperty.setValue(<new default value>)
        /// ```
        public mutating func setValue(_ value: T) {
            property.wrappedValue = value
        }

        public subscript<U>(dynamicMember keyPath: KeyPath<FeatureGroupProperty<T>, U>) -> U {
            property[keyPath: keyPath]
        }
    }

    public subscript<U>(dynamicMember keyPath: KeyPath<T, FeatureGroupProperty<U>>) -> PropertyProxy<U> {
        get {
            PropertyProxy(property: group.wrappedValue[keyPath: keyPath])
        }
        mutating set {
            group.override.setValue(
                newValue.wrappedValue,
                forKey: [group.key, group.wrappedValue[keyPath: keyPath].key].joined()
            )
        }
    }
}

extension ProviderResolvingObservableFeatureGroup where P == EmptyToggleProviderResolving {
    public init(
        key: String,
        debugDescription: String = "",
        provider: ToggleProvider
    ) {
        self.init(group: FeatureGroup(
            key: key,
            debugDescription: debugDescription,
            provider: provider
        ))
    }

    public init<Key: RawRepresentable>(
        key: Key,
        debugDescription: String = "",
        provider: ToggleProvider
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            debugDescription: debugDescription,
            provider: provider
        )
    }
}

extension ProviderResolvingObservableFeatureGroup {
    public init(
        key: String,
        debugDescription: String = ""
    ) {
        self.init(group: ProviderResolvingFeatureGroup(
            key: key,
            debugDescription: debugDescription
        ))
    }

    public init<Key: RawRepresentable>(
        key: Key,
        debugDescription: String = ""
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            debugDescription: debugDescription
        )
    }
}
