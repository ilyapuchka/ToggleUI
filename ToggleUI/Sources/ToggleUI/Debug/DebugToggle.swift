
public internal(set) var debugToggles = [DebugToggle]()

public protocol DebugToggleConvertible {
    var debugToggle: DebugToggle { get }
}

public protocol FeatureGroupDebugToggleConvertible {
    func debugToggle(
        groupKey: String,
        userInfo: [String: Any],
        provider: ToggleProvider
    ) -> DebugToggle
}

/// Debug representation of a feature toggle or feature group's property used by DebugView
public struct DebugToggle: Identifiable {
    public let type: Any.Type
    public let key: String
    public let description: String
    public let value: () throws -> AnyHashable
    public let remoteValue: (() throws -> AnyHashable)?
    public let debugValues: [AnyHashable]
    public let defaultValue: AnyHashable
    public let provider: ToggleProvider
    public let toggleType: Any.Type

    public var groupToggles: [DebugToggle]

    public var isGroup: Bool {
        !groupToggles.isEmpty
    }

    public mutating func override(with value: AnyHashable?) {
        provider.override.setValue(value, forKey: key)
    }

    public var id: String {
        key + "\(type)" + "\(toggleType)"
    }

    public func valueOrDefault() -> AnyHashable {
        var error: Error?
        return valueOrDefault(error: &error)
    }

    public func valueOrDefault(error outError: inout Error?) -> AnyHashable {
        do {
            return try value()
        } catch {
            outError = error
            return defaultValue
        }
    }
}

extension ProviderResolvingFeatureToggle: DebugToggleConvertible {
    public func debugToggle(toggleType: Any.Type) -> DebugToggle {
        DebugToggle(
            type: T.self,
            key: self.key,
            description: self.debugDescription,
            value: { try self.provider.effectiveValue(for: self) },
            remoteValue: { try self.provider.value(for: self) },
            debugValues: self.debugValues,
            defaultValue: self.defaultValue,
            provider: self.provider,
            toggleType: toggleType,
            groupToggles: []
        )
    }

    public var debugToggle: DebugToggle {
        debugToggle(toggleType: Self.self)
    }
}

extension ObservableFeatureToggle: DebugToggleConvertible {
    public var debugToggle: DebugToggle {
        toggle.debugToggle(toggleType: Self.self)
    }
}

extension ProviderResolvingFeatureGroup: DebugToggleConvertible {
    func childDebugToggle(
        _ child: FeatureGroupDebugToggleConvertible,
        groupKey: String,
        userInfo: [String: Any],
        provider: ToggleProvider
    ) -> DebugToggle {
        var debugToggle = child.debugToggle(
            groupKey: groupKey,
            userInfo: userInfo,
            provider: provider
        )
        debugToggle.groupToggles = Mirror(debugToggle.defaultValue).children().map { (child: FeatureGroupDebugToggleConvertible) in
            childDebugToggle(
                child,
                groupKey: debugToggle.key,
                userInfo: userInfo,
                provider: provider
            )
        }
        return debugToggle
    }

    func debugToggle(toggleType: Any.Type) -> DebugToggle {
        var debugToggle = toggle.debugToggle(toggleType: Self.self)
        debugToggle.groupToggles = Mirror(T()).children().map { (child: FeatureGroupDebugToggleConvertible) in
            childDebugToggle(
                child,
                groupKey: self.toggle.key,
                userInfo: self.toggle.userInfo,
                provider: self.toggle.provider
            )
        }
        return debugToggle
    }

    public var debugToggle: DebugToggle {
        debugToggle(toggleType: Self.self)
    }
}

extension ObservableFeatureGroup: DebugToggleConvertible {
    public var debugToggle: DebugToggle {
        group.debugToggle(toggleType: Self.self)
    }
}

extension FeatureGroupProperty: FeatureGroupDebugToggleConvertible {
    public func debugToggle(
        groupKey: String,
        userInfo: [String: Any],
        provider: ToggleProvider,
        toggleType: Any.Type
    ) -> DebugToggle {
        let toggle = FeatureToggle(
            key: [groupKey, self.key].joined(),
            defaultValue: defaultValue,
            userInfo: userInfo,
            debugValues: debugValues,
            debugDescription: debugDescription,
            get: { decoder in
                var decoder = decoder
                decoder.key = groupKey
                return try self.get(decoder)
            },
            provider: provider
        )
        return toggle.debugToggle(toggleType: toggleType)
    }

    public func debugToggle(
        groupKey: String,
        userInfo: [String: Any],
        provider: ToggleProvider
    ) -> DebugToggle {
        debugToggle(
            groupKey: groupKey,
            userInfo: userInfo,
            provider: provider,
            toggleType: Self.self
        )
    }
}
