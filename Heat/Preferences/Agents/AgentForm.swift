import SwiftUI
import OSLog
import SharedKit
import GenKit
import HeatKit

private let logger = Logger(subsystem: "AgentForm", category: "Heat")

struct AgentForm: View {
    @Environment(AgentsProvider.self) var agentsProvider
    @Environment(\.dismiss) private var dismiss
    
    @State var agent: Agent
    
    @State private var newToolName: String = ""
    @State private var isShowingAlert = false
    @State private var error: ImagePickerError? = nil
    
    var body: some View {
        Form {
            Section("Info") {
                TextField("ID", text: $agent.id)
                TextField("Name", text: $agent.name)
            }
            Section("Tools") {
                ForEach(Array(agent.toolIDs.sorted(by: <)), id: \.self) { toolID in
                    Text(toolID)
                        .swipeActions {
                            Button(role: .destructive) {
                                agent.toolIDs.remove(toolID)
                            } label: {
                                Label("Trash", systemImage: "trash")
                            }
                        }
                }
            }
            Section {
                NavigationLink("Add Tool") {
                    AgentTool { name in
                        guard !name.isEmpty else { return }
                        agent.toolIDs.insert(name)
                    }
                }
            }
            Section("Instructions") {
                TextField("Instructions", text: $agent.instructions, axis: .vertical)
                    .font(.system(size: 14, design: .monospaced))
            }
        }
        .appFormStyle()
        .navigationTitle("Agent")
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
        Task { try await agentsProvider.upsert(agent) }
        dismiss()
    }
}

struct AgentPicture: View {
    @Environment(ImagePickerViewModel.self) private var viewModel
    
    let picture: Asset?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "pencil")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 32, height: 32)
                .foregroundStyle(.white)
                .background(.tint, in: .circle)
                .offset(x: 4, y: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AgentTool: View {
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