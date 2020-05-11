import Combine
import SwiftUI

@dynamicMemberLookup
public class AnyFeatureGroup<T: FeatureGroupDecodable>: ObservableObject {
    @Published public private(set) var wrappedValue: T
    private var getWrappedValue: (() -> T)?
    private var cancellable: AnyCancellable?

    public init<P>(_ group: ProviderResolvingObservableFeatureGroup<T, P>) {
        self.wrappedValue = group.group.toggle.defaultValue
        self.cancellable = group.wrappedValue.sink { [weak self] value in
            self?.wrappedValue = value
        }
    }

    public init<P>(_ group: ProviderResolvingFeatureGroup<T, P>) {
        self.wrappedValue = group.wrappedValue
        self.getWrappedValue = { group.wrappedValue }
    }

    public subscript<U>(dynamicMember keyPath: KeyPath<T, FeatureGroupProperty<U>>) -> Binding<U> {
        return Binding(
            get: { (self.getWrappedValue?() ?? self.wrappedValue)[keyPath: keyPath].wrappedValue },
            set: { _ in }
        )
    }
}

@dynamicMemberLookup
public class AnyMutableFeatureGroup<T: FeatureGroupDecodable>: ObservableObject {
    @Published public private(set) var wrappedValue: T
    private var getWrappedValue: (() -> T)?
    private var update: (T, Any, String) -> Void
    private var cancellable: AnyCancellable?

    public init<P>(_ group: ProviderResolvingObservableFeatureGroup<T, P>) {
        self.wrappedValue = group.group.toggle.defaultValue
        self.update = { _, _, _ in }
        self.cancellable = group.wrappedValue.sink { [weak self] value in
            guard self?.wrappedValue != value else { return }
            self?.wrappedValue = value
        }
        self.update = { [weak self] newWrappedValueValue, newPropertyValue, propertyKey in
            self?.wrappedValue = newWrappedValueValue
            group.group.toggle.override.setValue(newPropertyValue, forKey: [group.group.toggle.key, propertyKey].joined())
        }
    }

    public init<P>(_ group: ProviderResolvingFeatureGroup<T, P>) {
        self.wrappedValue = group.wrappedValue
        self.getWrappedValue = { group.wrappedValue }
        self.update = { _, _, _ in }
        self.update = { [weak self] newWrappedValueValue, newPropertyValue, propertyKey in
            self?.wrappedValue = newWrappedValueValue
            group.toggle.override.setValue(newPropertyValue, forKey: [group.toggle.key, propertyKey].joined())
        }
    }

    public subscript<U>(dynamicMember keyPath: KeyPath<T, FeatureGroupProperty<U>>) -> Binding<U> {
        return Binding(
            get: { (self.getWrappedValue?() ?? self.wrappedValue)[keyPath: keyPath].wrappedValue },
            set: { newValue in
                self.wrappedValue[keyPath: keyPath].update(newValue)
                self.update(self.wrappedValue, newValue, self.wrappedValue[keyPath: keyPath].key)
            }
        )
    }
}
