import SwiftUI
import HeatKit

struct MemoryForm: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var text: String = ""
    
    let action: (String) -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Form {
            TextField("Content", text: $text)
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
        #if os(macOS)
        .formStyle(.grouped)
        .frame(width: 400)
        .frame(minHeight: 450)
        #endif
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