import SwiftUI
import HeatKit

struct FileForm: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    let fileID: String

    @State private var name: String = ""

    var body: some View {
        Form {
            TextField("Name", text: $name)
        }
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    handleSave()
                } label: {
                    Text("Done")
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
        }
        .onAppear {
            handleAppear()
        }
    }

    func handleAppear() {
        do {
            let file = try API.shared.file(fileID)
            name = file.name ?? ""
        } catch {
            print(error)
        }
    }

    func handleSave() {
        do {
            var file = try API.shared.file(fileID)
            file.name = name.isEmpty ? nil : name

            Task {
                try await API.shared.fileUpdate(file)
                dismiss()
            }
        } catch {
            print(error)
        }
    }
}
