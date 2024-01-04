import SwiftUI
import GenKit
import HeatKit

struct TemplateForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var template: Template = .empty
    @State var messages: [(String, String)] = [("system", "")]
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $template.title)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif
                TextField("Subtitle", text: Binding<String>(
                    get: { template.subtitle ?? "" },
                    set: { template.subtitle = $0.isEmpty ? nil : $0 }
                ))
            }
            
            ForEach($messages.indices, id: \.self) { index in
                Section {
                    Picker("Role", selection: $messages[index].0) {
                        Text("System").tag(Message.Role.system)
                        Text("Assistant").tag(Message.Role.assistant)
                        Text("User").tag(Message.Role.user)
                    }
                    TextField("Content", text: $messages[index].1, axis: .vertical)
                }
            }
            
            Section {
                Button("Add Message", action: handleAddMessage)
            }
        }
        .navigationTitle("New Template")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
        }
        .onAppear {
            messages = template.messages.map { ($0.role.rawValue, $0.content ?? "") }
            if messages.isEmpty { messages = [("system", "")] }
        }
    }
    
    func handleDone() {
        template.messages = messages.map {
            guard !$0.1.isEmpty else { return nil }
            return Message(kind: .instruction, role: .init(rawValue: $0.0)!, content: $0.1)
        }.compactMap { $0 }
        store.upsert(template: template)
        dismiss()
    }
    
    func handleAddMessage() {
        var message: (String, String)
        if let lastMessage = template.messages.last {
            switch lastMessage.role {
            case .system:
                message = (Message.Role.assistant.rawValue, "")
            case .assistant, .tool:
                message = (Message.Role.user.rawValue, "")
            case .user:
                message = (Message.Role.assistant.rawValue, "")
            }
        } else {
            message = (Message.Role.system.rawValue, "")
        }
        messages.append(message)
    }
}

#Preview {
    TemplateForm(template: .empty)
        .environment(Store.preview)
}
