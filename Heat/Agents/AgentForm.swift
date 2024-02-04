import SwiftUI
import OSLog
import PhotosUI
import SharedKit
import GenKit
import HeatKit

private let logger = Logger(subsystem: "AgentForm", category: "Mate")

struct AgentForm: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State var agent: Agent
    @State var instructions: [(String, String)] = []
    @State var viewModel = ImagePickerViewModel()
    
    @State private var isShowingAlert = false
    @State private var error: ImagePickerError? = nil
    
    var body: some View {
        Form {
            Section {
                PhotosPicker(selection: $viewModel.imageSelection, matching: .images, photoLibrary: .shared()) {
                    AgentPicture(picture: agent.picture)
                        .environment(viewModel)
                }
            }
            .listRowBackground(Color.clear)
            
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
        do {
            switch viewModel.imageState {
            case .empty:
                break
            case .loading:
                self.error = .transferInProgress
                isShowingAlert = true
                return
            case .success:
                let filename = try viewModel.write()
                agent.picture = .init(name: filename, kind: .image, location: .filesystem)
            case .failure(let error):
                self.error = error
                isShowingAlert = true
                return
            }
            agent.instructions = instructions
                .filter({ !$0.1.isEmpty })
                .map {
                    Message(kind: .instruction, role: .init(rawValue: $0.0)!, content: $0.1)
                }
            store.upsert(agent: agent)
            dismiss()
        } catch let error as ImagePickerError {
            self.error = error
            isShowingAlert = true
        } catch {
            logger.error("failed to save image: \(error)")
        }
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
        HStack {
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                Group {
                    switch viewModel.imageState {
                    case .empty:
                        if let picture {
                            PictureView(asset: picture)
                        } else {
                            Rectangle()
                        }
                    case .loading:
                        Rectangle()
                    case .success(let image):
                        #if os(macOS)
                        Image(nsImage: image).resizable()
                        #else
                        Image(uiImage: image).resizable()
                        #endif
                    case .failure:
                        Rectangle()
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Squircle())
                .tint(.primary)
                
                Image(systemName: "pencil")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.white)
                    .background(.tint)
                    .clipShape(.circle)
                    .offset(x: 4, y: 4)
            }
            Spacer()
        }
    }
}

#Preview("Create Agent") {
    NavigationStack {
        AgentForm(agent: .empty)
    }.environment(Store.preview)
}

#Preview("Edit Agent") {
    let store = Store.preview
    let agent = Agent.preview
    
    return NavigationStack {
        AgentForm(agent: agent)
    }.environment(store)
}
