import Foundation
import Combine

public protocol DecoderCapturing: Decodable {
    var decoder: Decoder { get }
}

@propertyWrapper
public struct DecoderCaptured: DecoderCapturing {
    public var wrappedValue: Decoder { decoder }
    public let decoder: Decoder

    public init(from decoder: Decoder) throws {
        self.decoder = decoder
    }
}

extension KeyedDecodingContainer {
    public func decode(_: DecoderCaptured.Type, forKey key: Key) throws -> DecoderCaptured {
        try DecoderCaptured(from: superDecoder(forKey: key))
    }
}

public protocol CodableToggleProvider: ToggleProvider {
    associatedtype DecoderCaptured: DecoderCapturing

    var dataPublisher: AnyPublisher<Result<Data, Error>, Never> { get }
}

public extension CodableToggleProvider {
    func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) throws -> T {
        try value(for: toggle).single().get()
    }

    func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> T {
        try value(for: group.toggle)
    }

    func value<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        self.decoder(for: toggle).map { decoder in
            decoder.flatMap { decoder in
                Result {
                    try toggle.get(decoder)
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func value<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<T, Error>, Never> {
        value(for: group.toggle)
    }

    func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) throws -> ToggleDecoder {
        try decoder(for: toggle).single().get()
    }

    func decoder<T, P>(for toggle: ProviderResolvingFeatureToggle<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never> {
        dataPublisher
            .catch { Just<Result<Data, Error>>(.failure($0)) }
            .map { data in
                data.flatMap { data in
                    Result {
                        try CodableToggleDecoder(
                            key: toggle.key,
                            decoder: JSONDecoder().decode(Self.DecoderCaptured.self, from: data).decoder
                        )
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    func decoder<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) throws -> ToggleDecoder {
        try decoder(for: group).single().get()
    }

    func decoder<T, P>(for group: ProviderResolvingFeatureGroup<T, P>) -> AnyPublisher<Result<ToggleDecoder, Error>, Never> {
        dataPublisher
            .catch { Just<Result<Data, Error>>(.failure($0)) }
            .map { _ in
                Result {
                    try FeatureGroupDecoder(
                        key: group.toggle.key,
                        providerDecoder: self.decoder(for: group.toggle),
                        overrideDecoder: self.override.decoder(for: group.toggle)
                    )
                }
        }
        .eraseToAnyPublisher()
    }
}
