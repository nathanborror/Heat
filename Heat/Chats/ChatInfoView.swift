import SwiftUI
import HeatKit

struct ChatInfoView: View {
    @Environment(Store.self) private var store
    @Environment(ChatViewModel.self) private var chatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                ForEach(store.models) { model in
                    Button(action: { handleSelection(model) }) {
                        HStack {
                            Text(model.name)
                                .tint(.primary)
                            Spacer()
                            if model.id == chatViewModel.chat?.modelID {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Models")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Chat Info")
        .frame(idealWidth: 400, idealHeight: 400)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            Task {
                try await store.modelsLoad()
            }
        }
    }
    
    func handleSelection(_ model: Model) {
        chatViewModel.change(model: model)
        dismiss()
    }
}

