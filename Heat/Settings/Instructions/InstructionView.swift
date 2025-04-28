import SwiftUI
import HeatKit

struct InstructionsView: View {
    @Environment(AppState.self) var state

    @State var selection: String?

    var body: some View {
        #if os(macOS)
        HSplitView {
            InstructionList(selection: $selection)
                .frame(minWidth: 200, idealWidth: 200, maxWidth: 400)
                .listStyle(.bordered)
                .alternatingRowBackgrounds(.enabled)
                .environment(\.defaultMinListRowHeight, 32)
                .overlay(alignment: .bottom) {
                    Button {
                        selection = nil
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(.linearGradient(colors: [Color(hex: "#FAFAFA"), Color(hex: "#F5F5F5")], startPoint: .top, endPoint: .bottom))
                        .padding(1)
                    }
                    .buttonStyle(.plain)
                    .overlay {
                        Rectangle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    }
                }

            Group {
                InstructionForm(selection)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading)
            .layoutPriority(1)
        }
        #else
        NavigationStack {
            InstructionList(selection: $selection)
                .navigationTitle("Instructions")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(item: $selection) { fileID in
                    InstructionForm(fileID)
                }
        }
        #endif
    }
}
