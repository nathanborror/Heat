import SwiftUI
import OSLog
import SharedKit
import GenKit
import HeatKit

private let logger = Logger(subsystem: "TemplateForm", category: "App")

struct TemplateForm: View {
    @Environment(TemplatesProvider.self) var templatesProvider
    @Environment(\.dismiss) private var dismiss
    
    @State var template: Template
    
    @State private var newToolName: String = ""
    @State private var isShowingAlert = false
    @State private var error: ImagePickerError? = nil
    
    var body: some View {
        Form {
            Section("Info") {
                TextField("ID", text: $template.id)
                TextField("Name", text: $template.name)
                Picker("Kind", selection: $template.kind) {
                    ForEach(Template.Kind.allCases, id: \.self) {
                        Text($0.rawValue.capitalized).tag($0)
                    }
                }
            }
            Section("Tools") {
                ForEach(Array(template.toolIDs.sorted(by: <)), id: \.self) { toolID in
                    Text(toolID)
                        .swipeActions {
                            Button(role: .destructive) {
                                template.toolIDs.remove(toolID)
                            } label: {
                                Label("Trash", systemImage: "trash")
                            }
                        }
                }
            }
            Section {
                NavigationLink("Add Tool") {
                    TemplateTool { name in
                        guard !name.isEmpty else { return }
                        template.toolIDs.insert(name)
                    }
                }
            }
            Section("Instructions") {
                TextField("Instructions", text: $template.instructions, axis: .vertical)
                    .font(.system(size: 14, design: .monospaced))
            }
        }
        .appFormStyle()
        .navigationTitle("Template")
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
        }
        .alert(isPresented: $isShowingAlert, error: error) { _ in
            Button("Dismiss", role: .cancel) {
                error = nil
            }
        } message: { error in
            Text(error.recoverySuggestion)
        }
    }
    
    private func handleDone() {
        Task { try await templatesProvider.upsert(template) }
        dismiss()
    }
}

struct TemplateTool: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var text: String = ""
    
    let action: (String) -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Form {
            TextField("Name", text: $text)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .focused($isFocused)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            handleSubmit()
                        } label: {
                            Text("Done")
                        }
                    }
                }
        }
        .onAppear {
            isFocused = true
        }
    }
    
    func handleSubmit() {
        action(text.trimmingCharacters(in: .whitespacesAndNewlines))
        text = ""
        dismiss()
    }
}
