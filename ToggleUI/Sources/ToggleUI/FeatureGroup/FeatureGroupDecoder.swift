public protocol FeatureGroupDecodable: Hashable {
    init()
    init(decoder: ToggleDecoder) throws
}

public extension FeatureGroupDecodable {
    init(decoder: ToggleDecoder) throws {
        self = Self()

        Mirror(self).children().forEach { (toggle: FeatureGroupPropertyType) in
            toggle.decode(from: decoder)
        }
    }
}

extension Mirror {
    init(_ value: Any) {
        var mirror = Mirror(reflecting: value)
        if let hashable = value as? AnyHashable {
            mirror = Mirror(reflecting: hashable.base)
        }
        if case .optional = mirror.displayStyle, let optional = mirror.children.first {
            mirror = Mirror(reflecting: optional.value)
        }
        self = mirror
    }

    func children<T>(of type: T.Type = T.self) -> [T] {
        children.compactMap {
            $0.value as? T
        }
    }
}

/// Decoder that can decode feature group properties. First it tries to decode value from override decoder and then falls back to provider decoder.
/// This is so that when some properties of a feature group are overridden the decode can still decode other properties of the group using provider decoder
public struct FeatureGroupDecoder: ToggleDecoder {
    var providerDecoder: ToggleDecoder
    var overrideDecoder: ToggleDecoder

    public init(
        key: String,
        providerDecoder: ToggleDecoder,
        overrideDecoder: ToggleDecoder
    ) {
        self.key = key
        self.providerDecoder = providerDecoder
        self.overrideDecoder = overrideDecoder
    }

    public var key: String {
        didSet {
            providerDecoder.key = key
            overrideDecoder.key = key
        }
    }

    public func decode() throws -> Bool {
        do {
            return try overrideDecoder.decode()
        } catch {
            return try providerDecoder.decode()
        }
    }

    public func decode() throws -> String {
        do {
            return try overrideDecoder.decode()
        } catch {
            return try providerDecoder.decode()
        }
    }

    public func decode(key: String) throws -> Bool {
        do {
            return try overrideDecoder.decode(key: key)
        } catch {
            return try providerDecoder.decode(key: key)
        }
    }

    public func decode(key: String) throws -> String {
        do {
            return try overrideDecoder.decode(key: key)
        } catch {
            return try providerDecoder.decode(key: key)
        }
    }
}
