import Foundation
import ToggleUI
import Combine

let values: [String: Any] = [
    "a": "true",
    "b": "B",
    "c": "c",
    "d": "true",
    "e": "b",
    "config": [
        "f": "F",
        "g": true
    ]
]

let inMemoryProvider = InMemoryToggleProvider(values: values)

let userDefaultsProvider = UserDefaultsToggleProvider(
    userDefaults: UserDefaults.standard
)

var currentProvider: ToggleProvider = OverridableToggleProvider(
    provider: inMemoryProvider,
    override: userDefaultsProvider
)

struct Config: DecoderCapturing {
    enum CodingKeys: String, CodingKey {
        case decoder = "config"
    }

    @DecoderCaptured var decoder: Decoder
}

class URLSessionRemoteToggleProvider<T: DecoderCapturing>: CodableToggleProvider {
    var name: String = "Remote Config"
    typealias DecoderCaptured = T

    let dataPublisher: AnyPublisher<Result<Data, Error>, Never> = DataPublisher.publisher
}

class ConfigPublisher {
    var bag = Set<AnyCancellable>()
    let publisher: AnyPublisher<Result<Data, Error>, Never>

    init() {
        let subject = CurrentValueSubject<Result<Data, Error>?, Never>(nil)
        URLSession.shared
            .dataTaskPublisher(for: URL(string: "https://api.jsonbin.io/b/5eb83d1747a2266b147628b7/5")!)
            .map { data, _ in data }
            .sink(
                receiveCompletion: { _ in },
                receiveValue: {
//                    subject.send(.failure(URLError.init(.notConnectedToInternet)))
                    subject.send(.success($0))
            }
        ).store(in: &bag)
        self.publisher = subject.filter { $0 != nil }.map { $0! }.eraseToAnyPublisher()
    }
}

let DataPublisher = ConfigPublisher()

let urlConfigProvider = OverridableToggleProvider(
    provider: URLSessionRemoteToggleProvider<Config>(),
    override: userDefaultsProvider
)

let urlProvider = OverridableToggleProvider(
    provider: URLSessionRemoteToggleProvider<DecoderCaptured>(),
    override: userDefaultsProvider
)

struct RemoteToggleProviderResolver: ToggleProviderResolving {
    static func makeProvider() -> ToggleProvider {
        urlProvider
    }
}

struct RemoteConfigToggleProviderResolver: ToggleProviderResolving {
    static func makeProvider() -> ToggleProvider {
        urlConfigProvider
    }
}

typealias RemoteFeatureToggle<T: Hashable> = ProviderResolvingObservableFeatureToggle<T, RemoteToggleProviderResolver>
typealias RemoteFeatureGroup<T: FeatureGroupDecodable> = ProviderResolvingObservableFeatureGroup<T, RemoteToggleProviderResolver>
typealias RemoteConfigFeatureToggle<T: Hashable> = ProviderResolvingObservableFeatureToggle<T, RemoteConfigToggleProviderResolver>
typealias RemoteConfigFeatureGroup<T: FeatureGroupDecodable> = ProviderResolvingObservableFeatureGroup<T, RemoteConfigToggleProviderResolver>

typealias RemoteFeatureToggleValue<T: Hashable> = ProviderResolvingFeatureToggle<T, RemoteToggleProviderResolver>

struct Toggles: WithDefaults {

    enum ABTest: String, CaseIterable {
        case a, b, c
    }

    struct Module: FeatureGroupDecodable {
        @FeatureGroupProperty(key: "feature3")
        var feature3: String

        init() {}
    }

    struct Config: FeatureGroupDecodable {
        @FeatureGroupProperty(key: "f")
        var f: String
        @FeatureGroupProperty(key: "g")
        var g: Bool

        init() {}
    }

    @FeatureToggle(key: "a", provider: currentProvider)
    var toggleA: Bool

    @FeatureToggle(key: "b", provider: currentProvider)
    var toggleB: String

    @FeatureToggle<ABTest>(key: "c", defaultValue: .a, provider: currentProvider)
    var toggleC: ABTest

    @ObservableFeatureToggle(key: "d", provider: currentProvider)
    var toggleD: AnyPublisher<Bool, Never>

    @ObservableFeatureToggle(key: "e", defaultValue: .a, provider: currentProvider)
    var toggleE: AnyPublisher<ABTest, Never>

    @FeatureToggle(key: "config.f", provider: currentProvider)
    var toggleF: String

    @FeatureToggle(key: "config.g", provider: currentProvider)
    var toggleG: Bool

    @FeatureGroup(
        key: "config",
        debugDescription: "Some config",
        provider: currentProvider
    )
    var toggleConfig: Config

    @RemoteFeatureToggle(key: "feature1")
    var value1: AnyPublisher<String, Never>

    @RemoteFeatureToggleValue(key: "feature1")
    var value1sync: String

    @RemoteFeatureToggle(key: "feature4")
    var value4: AnyPublisher<String, Never>

    @RemoteConfigFeatureToggle(key: "feature2")
    var value2: AnyPublisher<Bool, Never>

    @RemoteConfigFeatureToggle(key: "module.feature3")
    var value3: AnyPublisher<String, Never>

    @RemoteConfigFeatureGroup(key: "module")
    var value3Decodable: AnyPublisher<Module, Never>
}
