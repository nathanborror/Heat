import SwiftUI
import HeatKit

struct AgentForm: View {
    @Environment(Store.self) private var store
    
    @State var name = ""
    @State var system = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
            } header: {
                Text("Name")
            }
            
            Section {
                TextField("System Prompt", text: $system)
            } header: {
                Text("System Prompt")
            }
        }
    }
}

#Preview {
    AgentForm()
}
