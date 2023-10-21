import SwiftUI
import HeatKit

struct SettingsView: View {
    @Binding var settings: Settings
    
    var body: some View {
        Form {
            Section {
                TextField("Model Name", text: $settings.model)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                Picker("Model Name", selection: $settings.model) {
                    Text("Llama2 7B Chat").tag("llama2:7b-chat")
                    Text("Llama2 13B Chat").tag("llama2:13b-chat")
                    Text("Llama2 70B Chat").tag("llama2:70b-chat")
                    Divider()
                    Text("Llama2 70B Chat Uncensored").tag("llama2-uncensored:70b-chat")
                    Divider()
                    Text("Mistral 7B Text").tag("mistral:text")
                    Text("Mistral 7B Instruct").tag("mistral:instruct")
                    Text("Mistral 7B Samantha").tag("samantha-mistral:7b-v1.2-text-fp16")
                }
            } header: {
                Text("Model")
            }
            
            Section {
                TextField("Host Address", text: $settings.host)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Host")
            } footer: {
                Text("Example: 127.0.0.1:8080")
            }
        }
    }
}
