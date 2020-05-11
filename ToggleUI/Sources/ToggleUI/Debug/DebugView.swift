import Combine
import SwiftUI

extension DebugToggle {
    var isBoolean: Bool {
        type == Bool.self || type == Optional<Bool>.self
    }

    var isString: Bool {
        type == String.self || type == Optional<String>.self
    }

    var typeDescription: String {
        let typeDescription = String(describing: type)
        return typeDescription.hasPrefix("Optional<")
            ? String(typeDescription.dropFirst("Optional<".count).dropLast())
            : typeDescription
    }

    func isSelected(debugValue: AnyHashable, selectedValue: AnyHashable) -> Bool {
        selectedValue.hashValue == debugValue.hashValue
            || selectedValue.hashValue == Optional.some(debugValue).hashValue
    }
}

extension View {

    func infoAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "OK", style: .default, handler: { _ in })
        alertController.addAction(cancelAction)

        var root = UIApplication.shared.windows.first?.rootViewController
        while root?.presentedViewController != nil {
            root = root?.presentedViewController
        }
        root?.present(alertController, animated: true, completion: nil)
    }

    func inputAlert(value: AnyHashable, completion: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "Enter new value", message: nil, preferredStyle: .alert)

        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = String(describing: value)
        }

        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
            let value = alertController.textFields?.first?.text
            completion(value)
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ in completion(nil) })


        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        var root = UIApplication.shared.windows.first?.rootViewController
        while root?.presentedViewController != nil {
            root = root?.presentedViewController
        }
        root?.present(alertController, animated: true, completion: nil)
    }
}

class DebugViewState: ObservableObject {
    @Published var toggles: [DebugToggle] = ToggleUI.debugToggles
    @Published var providers: Set<String> = []
}

/// A view that displays and allows to override feature toggles at the application runtime.
public struct DebugView: View {
    @ObservedObject var state = DebugViewState()

    public init() {}

    var filters: some View {
        let items = state.toggles.map { $0.provider.name }
        let texts = NSOrderedSet(array: items).map {
            String(describing: $0)
        }
        return VStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Providers:").bold().font(.callout)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(texts.indices) { index -> Tag in
                                let text = texts[index]
                                return Tag(text, color: self.state.providers.contains(text)
                                    ? Color.green
                                    : Color.gray
                                ) {
                                    if self.state.providers.contains(text) {
                                        self.state.providers.remove(text)
                                    } else {
                                        self.state.providers.insert(text)
                                    }
                                }
                            }
                        }.padding(2)
                    }
                }
            }.padding([.horizontal, .top])
            Divider()
        }.padding(.bottom, -8)
    }

    public var body: some View {
        NavigationView {
            VStack {
                filters
                ToggleList(toggles: $state.toggles) {
                    self.state.providers.contains($0.provider.name) || self.state.providers.isEmpty
                }
            }
            .navigationBarTitle("Feature Toggles", displayMode: .inline)
            .navigationBarItems(trailing: ResetAll(toggles: self.$state.toggles))
        }
    }
}

struct ResetAll: View {
    @Binding var toggles: [DebugToggle]

    var body: some View {
        Button("Reset all", action: {
            self.toggles = self.toggles.map { (toggle) in
                var toggle = toggle
                toggle.override(with: nil)
                return toggle
            }
        }).disabled(!toggles.contains(where: { toggle in
            toggle.provider.override.hasValue(for: toggle.key)
        }))
    }
}

struct ToggleList: View {
    @Binding var toggles: [DebugToggle]
    let filter: (DebugToggle) -> Bool

    init(toggles: Binding<[DebugToggle]>, filter: @escaping (DebugToggle) -> Bool = { _ in true }) {
        self._toggles = toggles
        self.filter = filter
    }

    var body: some View {
        List {
            ForEach(toggles.filter(filter)) { toggle in
                ToggleCell(toggle: Binding<DebugToggle>(get: {
                    self.toggles.first(where: { $0.id == toggle.id })!
                }, set: { toggle in
                    let index = self.toggles.firstIndex(where: { $0.id == toggle.id })!
                    self.toggles[index] = toggle
                }))
            }
        }
    }
}

extension View {
    func push<V: View>(isActive: Binding<Bool>, @ViewBuilder destination: () -> V) -> some View {
        background(
            NavigationLink(
                destination: destination(),
                isActive: isActive,
                label: { EmptyView() }
            )
        )
    }
}

struct ToggleCell: View {
    @Binding var toggle: DebugToggle

    @ViewBuilder
    var body: some View {
        if toggle.isGroup {
            NavigationLink(destination: GroupView(toggle: toggle)) {
                content
            }
        }
        else {
            content
        }
    }

    var content: some View {
        HStack(alignment: .center) {
            ToggleDescription(toggle: $toggle)
            Spacer()
            if toggle.isBoolean {
                BooleanToggle(toggle: $toggle)
            } else if toggle.isString {
                StringToggle(toggle: $toggle)
            } else if !toggle.debugValues.isEmpty {
                EnumToggle(toggle: $toggle)
            } else {
                Text(toggle.typeDescription).lineLimit(1)
            }
        }
    }
}

struct ToggleDescription: View {
    @Binding var toggle: DebugToggle

    var body: some View {
        var error: Error?
        _ = toggle.valueOrDefault(error: &error)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Key: ").bold() + Text(toggle.key)
            if !toggle.description.isEmpty {
                Text(toggle.description)
            }
            HStack {
                Tag(toggle.provider.name, color: Color.green)
                if toggle.provider.override.hasValue(for: toggle.key) {
                    Tag("Overriden", color: Color.orange) {
                        self.toggle.override(with: nil)
                    }
                }
                if error != nil {
                    Tag("⚠️ Error", color: Color.red) {
                        self.infoAlert(title: "Error", message: error!.localizedDescription)
                    }
                }
            }
        }.fixedSize(horizontal: true, vertical: true)
    }
}

struct Tag: View {
    let text: String
    let color: Color?
    let action: (() -> Void)?

    init(_ text: String, color: Color?, action: (() -> Void)? = nil) {
        self.text = text
        self.color = color
        self.action = action
    }
    var body: some View {
        Text(text)
            .font(.footnote)
            .padding(4)
            .background(color ?? .white)
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: 1))
            .onTapGesture {
                self.action?()
        }
    }
}

struct BooleanToggle: View {
    @Binding var toggle: DebugToggle

    var body: some View {
        Toggle(
            "",
            isOn: Binding<Bool>(
                get: { self.toggle.valueOrDefault() as? Bool == true },
                set: { newValue in self.toggle.override(with: newValue) }
            )
        ).fixedSize(horizontal: true, vertical: false)
    }
}

struct StringToggle: View {
    @Binding var toggle: DebugToggle

    var body: some View {
        let value = toggle.valueOrDefault()

        return Button(action: {
            self.inputAlert(value: value) { newValue in
                if let newValue = newValue, !newValue.isEmpty {
                    self.toggle.override(with: newValue)
                }
            }
        }) {
            Text(String(describing: value))
        }
    }
}

struct EnumToggle: View {
    @Binding var toggle: DebugToggle
    @State var showsActionSheet: Bool = false

    var body: some View {
        let value = toggle.valueOrDefault()
        let selectedValue = toggle.debugValues.first {
            toggle.isSelected(debugValue: $0, selectedValue: value)
        } ?? toggle.type as Any

        return Button(String(describing: selectedValue)) {
            self.showsActionSheet = true
        }
        .actionSheet(isPresented: $showsActionSheet) {
            ActionSheet(title: Text("Select a new value"), message: nil, buttons:
                toggle.debugValues.map { debugValue -> ActionSheet.Button in
                    self.toggle.isSelected(debugValue: debugValue, selectedValue: value)
                        ? .destructive(Text(verbatim: "\(debugValue)"))
                        : .default(Text(verbatim: "\(debugValue)"))
                } + [.cancel()]
            )
        }
    }
}

// Separate state for group views as bindings seem to break updates on nested views
class GroupViewState: ObservableObject {
    @Published var toggle: DebugToggle

    init(toggle: DebugToggle) {
        self.toggle = toggle
    }
}

struct GroupView: View {
    @ObservedObject var state: GroupViewState

    init(toggle: DebugToggle) {
        self.state = GroupViewState(toggle: toggle)
    }

    var header: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Type: ").bold() + Text(String(describing: state.toggle.typeDescription))
                Text(state.toggle.description)
                Spacer()
            }.padding([.horizontal, .top])
            Divider()
        }
        .padding(.bottom, -8)
        .fixedSize(horizontal: false, vertical: true)
    }

    var body: some View {
        VStack {
            header
            ToggleList(toggles: $state.toggle.groupToggles)
        }
        .navigationBarTitle("Feature Group", displayMode: .inline)
    }
}
