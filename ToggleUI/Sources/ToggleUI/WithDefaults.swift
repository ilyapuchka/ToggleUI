public protocol WithDefaults {
}

public extension WithDefaults {
    func withDefaults(_ defaults: (inout Self) -> Void = { _ in }) -> Self {
        var copy = self
        defaults(&copy)

        #if DEBUG
        ToggleUI.debugToggles = Mirror(reflecting: copy).children()
            .reduce(into: [DebugToggle]()) { (debugToggles, child: DebugToggleConvertible) in
                let debugToggle = child.debugToggle
                if !debugToggles.contains(where: { $0.id == debugToggle.id }) {
                    debugToggles.append(debugToggle)
                }
            }
        #endif

        return copy
    }
}

public struct EmptyToggles: WithDefaults {
    public init() {}
}
