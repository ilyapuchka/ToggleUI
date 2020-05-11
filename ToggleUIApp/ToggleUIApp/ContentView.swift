import SwiftUI
import Combine
import ToggleUI

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}

struct RootView: View {
    @State var showingDebugView: Bool = false
    
    @ObservedObject var toggleA = AnyFeatureToggle(toggles.$toggleA)
    @ObservedObject var toggleD = AnyMutableFeatureToggle(toggles.$toggleD)
    @ObservedObject var value1 = AnyMutableFeatureGroup(toggles.$value3Decodable)
    @ObservedObject var config = AnyFeatureGroup(toggles.$toggleConfig)
    
    var body: some View {
        NavigationView {
            Form {
                Toggle("toggleA", isOn: toggleA.binding)
                Toggle("toggleD", isOn: toggleD.binding)
                TextField("value1", text: value1.$feature3)
                Toggle("toggleG", isOn: config.$g)
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Debug") {
                self.showingDebugView = true
            })
        }.sheet(isPresented: $showingDebugView) {
            ToggleUI.DebugView()
        }
    }
}
