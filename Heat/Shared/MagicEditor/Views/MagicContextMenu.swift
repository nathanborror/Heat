import SwiftUI

struct MagicContextMenu: View {
    @Environment(\.colorScheme) private var colorScheme

    var manager: MagicContextMenuManager

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(manager.options.indices, id: \.self) { index in
                Button(action: {
                    manager.selection = index
                    manager.handleSelection()
                }) {
                    Text(manager.options[index].label)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(manager.selection == index ? Color.accentColor : Color.clear)
                        .foregroundColor(manager.selection == index ? Color.white : Color.primary)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
                .shadow(radius: 1)
        )
        .onAppear {
            manager.selection = 0
        }
    }
}

@MainActor
@Observable
final class MagicContextMenuManager {
    var options: [Option] = []
    var selection: Int = 0

    struct Option {
        let label: String
        let action: () -> Void
    }

    func handleSelectionMoveUp() {
        guard selection != 0 else { return }
        selection -= 1
    }

    func handleSelectionMoveDown() {
        guard selection < (options.count-1) else { return }
        selection += 1
    }

    func handleSelection() {
        options[selection].action()
    }
}
