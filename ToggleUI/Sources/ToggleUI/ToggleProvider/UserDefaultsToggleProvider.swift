import Foundation
import Combine

public enum UserDefaultsProviderResolver: ToggleProviderResolving {
    public static var provider = UserDefaultsToggleProvider(userDefaults: .standard)

    public static func makeProvider() -> ToggleProvider {
        provider
    }
}

public typealias UserDefaultsFeatureToggle<T: Hashable> = ProviderResolvingFeatureToggle<T, UserDefaultsProviderResolver>
public typealias UserDefaultsObservableFeatureToggle<T: Hashable> = ProviderResolvingObservableFeatureToggle<T, UserDefaultsProviderResolver>
public typealias UserDefaultsFeatureGroup<T: FeatureGroupDecodable> = ProviderResolvingFeatureGroup<T, UserDefaultsProviderResolver>
public typealias UserDefaultsObservableFeatureGroup<T: FeatureGroupDecodable> = ProviderResolvingObservableFeatureGroup<T, UserDefaultsProviderResolver>

public class UserDefaultsToggleProvider: ToggleProvider, ToggleOverriding {
    public static let key = "toggles"
    public let userDefaults: UserDefaults
    private var values: [String: Any] {
        didSet { subject.send(values) }
    }
    private let subject: CurrentValueSubject<[String: Any], Never>

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        let values = userDefaults.dictionary(forKey: Self.key) ?? [:]
        self.values = values
        self.subject = CurrentValueSubject(values)
    }

    public func hasValue(for key: String) -> Bool {
        (try? read(values: values, key: key)) != nil
    }

    public func setValue(_ value: Any?, forKey key: String) {
        var values: Any? = self.values
        try? write(values: &values, key: key, value: value)
        userDefaults.setValue(values, forKey: Self.key)
        userDefaults.synchronize()
        self.values = values as! [String: Any]
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

    public func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never> {
        subject.map { values in
            .success(self.decoder(for: toggle))
        }.eraseToAnyPublisher()
    }

    public func decoder<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never> {
        subject.map { values in
            Result { try self.decoder(for: group) }
        }.eraseToAnyPublisher()
    }

    public func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        subject.map { _ in
            Result {
                try self.value(for: toggle)
            }
        }.eraseToAnyPublisher()
    }

    public func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        subject.map { _ in
            Result {
                try self.value(for: group)
            }
        }.eraseToAnyPublisher()
    }
}

func asDictionary(_ value: Any?, key: String) throws -> [String: Any] {
    guard let dict = value as? [String: Any] else {
        throw FeatureToggleDecodingError.typeMismatch(
            key: key,
            type: type(of: value),
            expected: [String: Any].self
        )
    }
    return dict
}

func asArray(_ value: Any?, index: Int) throws -> [Any?] {
    guard let array = value as? [Any?] else {
        throw FeatureToggleDecodingError.typeMismatch(
            key: "\(index)",
            type: type(of: value),
            expected: [Any?].self
        )
    }
    return array
}

func read(values: Any?, key: String) throws -> Any? {
    if key.isEmpty {
        return values
    }

    let (key, remainder) = CodingKeyPath(key).head

    if let index = key.intValue {
        let array = try asArray(values, index: index)
        guard index < array.count else {
            throw FeatureToggleDecodingError.keyNotFound(key: "\(index)")
        }
        return try read(values: array[index], key: remainder.stringValue)
    } else {
        let dict = try asDictionary(values, key: key.stringValue)
        guard let values = dict[key.stringValue] else {
            throw FeatureToggleDecodingError.keyNotFound(key: key.stringValue)
        }
        return try read(values: values, key: remainder.stringValue)
    }
}

func write(values: inout Any?, key: String, value: Any?) throws {
    if key.isEmpty {
        values = value
        return
    }

    let (key, remainder) = CodingKeyPath(key).head
    if let index = key.intValue {
        if values == nil {
            values = []
        }
        var array = try asArray(values, index: index)
        if index >= array.count {
            array.append(contentsOf: [Any?].init(repeating: nil, count: index - array.count + 1))
        }
        var item: Any? = array[index]
        try write(values: &item, key: remainder.stringValue, value: value)
        array[index] = item
        values = array
    } else {
        if values == nil {
            values = [String: Any]()
        }
        var dict = try asDictionary(values, key: key.stringValue)
        var item = dict[key.stringValue]
        try write(values: &item, key: remainder.stringValue, value: value)
        dict[key.stringValue] = item
        values = dict
    }
}
