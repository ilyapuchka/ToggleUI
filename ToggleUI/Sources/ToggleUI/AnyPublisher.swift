import Foundation
import Combine

extension AnyPublisher {
    struct NoValueError: Error {}

    func single() throws -> Output {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Output, Error>!
        var bag = Set<AnyCancellable>()

        self.sink(
            receiveCompletion: { (c) in
                switch c {
                case .finished:
                    result = .failure(NoValueError())
                case let .failure(error):
                    result = .failure(error)
                }
                semaphore.signal()
            },
            receiveValue: { (value) in
                result = .success(value)
                semaphore.signal()
            }
        ).store(in: &bag)

        semaphore.wait()

        return try result.get()
    }
}
