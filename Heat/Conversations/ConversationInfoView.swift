import SwiftUI
import HeatKit

struct ConversationInfoView: View {
    @Environment(Store.self) private var store
    @Environment(ConversationViewModel.self) private var viewModel
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
                            if model.id == viewModel.conversation?.modelID {
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
    }
    
    func handleSelection(_ model: Model) {
        viewModel.change(model: model)
        dismiss()
    }
}

