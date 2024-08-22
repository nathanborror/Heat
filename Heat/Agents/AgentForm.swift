import SwiftUI
import OSLog
import SharedKit
import GenKit
import HeatKit

private let logger = Logger(subsystem: "AgentForm", category: "Heat")

struct AgentForm: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var agent: Agent
    @State var instructions: [(String, String)] = []
    
    @State private var isShowingAlert = false
    @State private var error: ImagePickerError? = nil
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $agent.name)
            }
            
            ForEach($instructions.indices, id: \.self) { index in
                Section {
                    Picker("Role", selection: $instructions[index].0) {
                        Text("System").tag("system")
                        Text("Assistant").tag("assistant")
                        Text("User").tag("user")
                    }
                    TextField("Content", text: $instructions[index].1, axis: .vertical)
                }
                .swipeActions {
                    Button(role: .destructive, action: { handleDeleteInstruction(index) }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            
            Section {
                Button("Add Instruction", action: handleAddInstruction)
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        .frame(width: 400)
        .frame(minHeight: 450)
        #endif
        .navigationTitle("Agent")
        .interactiveDismissDisabled()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: handleDone)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: dismiss.callAsFunction)
            }
        }
        .alert(isPresented: $isShowingAlert, error: error) { _ in
            Button("Dismiss", role: .cancel) {
                error = nil
            }
        } message: { error in
            Text(error.recoverySuggestion)
        }
        .onAppear {
            instructions = agent.instructions.map { ($0.role.rawValue, $0.content ?? "") }
        }
    }
    
    private func handleDone() {
        agent.instructions = instructions
            .filter({ !$0.1.isEmpty })
            .map {
                Message(kind: .instruction, role: .init(rawValue: $0.0)!, content: $0.1)
            }
        
        Task { try await AgentProvider.shared.upsert(agent) }
        dismiss()
    }
    
    private func handleAddInstruction() {
        if let last = instructions.last {
            switch last.0 {
            case "system", "user":
                instructions.append(("assistant", ""))
            case "assistant":
                instructions.append(("user", ""))
            default:
                instructions.append(("system", ""))
            }
        } else {
            instructions.append(("system", ""))
        }
    }
    
    private func handleDeleteInstruction(_ index: Int) {
        instructions.remove(at: index)
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
                .background(.tint)
                .clipShape(.circle)
                .offset(x: 4, y: 4)
        }
        .frame(maxWidth: .infinity)
    }
}
