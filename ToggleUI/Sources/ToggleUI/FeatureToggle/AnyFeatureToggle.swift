import Combine
import SwiftUI

public class AnyFeatureToggle<T: Hashable>: ObservableObject {
    @Published public private(set) var wrappedValue: T
    private var getWrappedValue: (() -> T)?
    private var cancellable: AnyCancellable?
    
    public init<P>(_ toggle: ProviderResolvingObservableFeatureToggle<T, P>) {
        self.wrappedValue = toggle.projectedValue.toggle.defaultValue
        self.cancellable = toggle.wrappedValue.sink { [weak self] value in
            self?.wrappedValue = value
        }
    }

    public init<P>(_ toggle: ProviderResolvingFeatureToggle<T, P>) {
        self.wrappedValue = toggle.wrappedValue
        self.getWrappedValue = { toggle.wrappedValue }
    }

    public var binding: Binding<T> {
        Binding(get: getWrappedValue ?? { self.wrappedValue }, set: { _ in })
    }
}

public class AnyMutableFeatureToggle<T: Hashable>: ObservableObject {
    @Published public private(set) var wrappedValue: T
    private var getWrappedValue: (() -> T)?
    private var update: (T) -> Void
    private var cancellable: AnyCancellable?

    public init<P>(_ toggle: ProviderResolvingObservableFeatureToggle<T, P>) {
        self.wrappedValue = toggle.projectedValue.toggle.defaultValue
        self.update = { _ in }
        self.update = { [weak self] in
            self?.wrappedValue = $0
            toggle.toggle.override.setValue($0, forKey: toggle.toggle.key)
        }
        self.cancellable = toggle.wrappedValue.sink { [weak self] value in
            guard self?.wrappedValue != value else { return }
            self?.wrappedValue = value
        }
    }
    
    public init<P>(_ toggle: ProviderResolvingFeatureToggle<T, P>) {
        self.wrappedValue = toggle.wrappedValue
        self.getWrappedValue = { toggle.wrappedValue }
        self.update = { _ in }
        self.update = { [weak self] in
            self?.wrappedValue = $0
            toggle.override.setValue($0, forKey: toggle.key)
        }
    }
    
    public var binding: Binding<T> {
        Binding(get: getWrappedValue ?? { self.wrappedValue }, set: update)
    }
}
