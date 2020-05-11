/// Feature group property wrapper that accepts toggle provider as constructor parameter
public typealias FeatureGroup<T: FeatureGroupDecodable> = ProviderResolvingFeatureGroup<T, EmptyToggleProviderResolving>

/// Feature group is a collection of related feature toggles defined using `FeatureGroupProperty` property wrapper.
@propertyWrapper @dynamicMemberLookup
public struct ProviderResolvingFeatureGroup<T: FeatureGroupDecodable, P: ToggleProviderResolving> {
    public var toggle: ProviderResolvingFeatureToggle<T, P>

    /// Effective value of the feature group or its default value if computing effective value throws an error
    public var wrappedValue: T {
        (try? toggle.provider.effectiveValue(for: self))
            ?? toggle.defaultValue
    }

    /// Feature group itself
    /// - Note: Setter only updates default value of the backing feature toggle, should be only used in `WithDefaults` implementation
    public var projectedValue: Self {
        get { self }
        set { self.toggle.defaultValue = newValue.toggle.defaultValue }
    }

    public init(toggle: ProviderResolvingFeatureToggle<T, P>) {
        self.toggle = toggle
        self.defaultValue = DefaultValueProxy(wrappedValue: toggle.defaultValue)
    }

    /// Proxy to set default value of feature group's properties
    ///
    /// Example:
    /// ```
    /// myFeatures.$myFeatureGroup.defaultValue.$featureProperty = <new default value>
    /// ```
    public var defaultValue: DefaultValueProxy<T> {
        willSet { toggle.defaultValue = newValue.wrappedValue }
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
        toggle[keyPath: keyPath]
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
            PropertyProxy(property: wrappedValue[keyPath: keyPath])
        }
        mutating set {
            toggle.override.setValue(
                newValue.wrappedValue,
                forKey: [toggle.key, wrappedValue[keyPath: keyPath].key].joined()
            )
        }
    }
}

extension ProviderResolvingFeatureGroup where P == EmptyToggleProviderResolving {
    public init(
        key: String,
        debugDescription: String = "",
        provider: ToggleProvider
    ) {
        self.init(toggle: FeatureToggle(
            key: key,
            defaultValue: T(),
            debugValues: [],
            debugDescription: debugDescription,
            get: { try T(decoder: $0) },
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

extension ProviderResolvingFeatureGroup {
    public init(
        key: String,
        debugDescription: String = ""
    ) {
        self.init(toggle: ProviderResolvingFeatureToggle(
            key: key,
            defaultValue: T(),
            debugValues: [],
            debugDescription: debugDescription,
            get: { try T(decoder: $0) }
        ))
    }

    public init<Key: RawRepresentable>(
        key: Key,
        debugDescription: String = "",
        provider: ToggleProvider
    ) where Key.RawValue == String {
        self.init(
            key: key.rawValue,
            debugDescription: debugDescription
        )
    }
}
