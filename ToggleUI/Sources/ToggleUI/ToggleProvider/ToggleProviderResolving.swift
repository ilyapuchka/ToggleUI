public protocol ToggleProviderResolving {
    static func makeProvider() -> ToggleProvider
}

public struct EmptyToggleProviderResolving: ToggleProviderResolving {
    public static func makeProvider() -> ToggleProvider {
        fatalError("Not implemented, provider should be passed via constructor parameter")
    }
}
