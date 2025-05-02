import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "MessageField", category: "App")

struct MessageField: View {
    @Environment(AppState.self) var state
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.colorScheme) var colorScheme

    typealias ActionHandler = (String, [String: String]?, Set<String>?) -> Void

    let action: ActionHandler

    @State private var content = ""
    @State private var instructionFile: File? = nil

    @FocusState private var isFocused: Bool

    init(action: @escaping ActionHandler) {
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 0) {
                Menu {
                    ForEach(state.instructions) { file in
                        if let instruction = try? state.file(Instruction.self, fileID: file.id), instruction.kind == .template {
                            Button(file.name ?? "Untitled") {
                                instructionFile = file
                            }
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .modifier(ConversationInlineButtonModifier())
                }
                .buttonStyle(.plain)

                TextField("Message", text: $content, axis: .vertical)
                    .fixedSize(horizontal: false, vertical: true)
                    .textFieldStyle(.plain)
                    .padding(.vertical, verticalPadding)
                    .padding(.trailing, showInputPadding ? 16 : 0)
                    .frame(minWidth: 0, minHeight: minHeight)
                    .focused($isFocused)
                    #if os(macOS)
                    .onSubmit {
                        Task {
                            do {
                                try await handleSubmit()
                            } catch {
                                print(error)
                            }
                        }
                    }
                    #endif

                if showStopGenerating {
                    Button(action: handleStop) {
                        Image(systemName: "stop.fill")
                            .modifier(ConversationButtonModifier())
                    }
                    .buttonStyle(.plain)
                } else if showSubmit {
                    Button {
                        Task {
                            do {
                                try await handleSubmit()
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .modifier(ConversationButtonModifier())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .sheet(item: $instructionFile) { file in
                NavigationStack {
                    MessageInstructions(file: file) { (instructions, context, toolIDs) in
                        action(instructions, context, toolIDs)
                        clear()
                    }
                }
            }
        }
    }

    func handleSubmit() async throws {
        action(content, nil, nil)
        clear()
    }

    func handleStop() {
        conversationViewModel.cancel()
    }

    private func clear() {
        content = ""
    }

    private var showInputPadding: Bool      { !content.isEmpty }
    private var showStopGenerating: Bool    { false } // TODO: Fix this
    private var showSubmit: Bool            { !content.isEmpty }

    #if os(macOS)
    private var minHeight: CGFloat = 0
    private var verticalPadding: CGFloat = 9
    #else
    private var minHeight: CGFloat = 44
    private var verticalPadding: CGFloat = 11
    #endif
}

struct ConversationButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontWeight(.medium)
            .frame(width: width, height: height)
            .foregroundStyle(.white)
            .background(.tint, in: .rect(cornerRadius: 8))
            .padding(.vertical, 2)
    }

    #if os(macOS)
    private var width: CGFloat = 30
    private var height: CGFloat = 30
    #else
    private var width: CGFloat = 40
    private var height: CGFloat = 40
    #endif
}

struct ConversationInlineButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.secondary)
            .tint(.primary)
            .frame(width: width, height: height)
    }

    #if os(macOS)
    private var width: CGFloat = 34
    private var height: CGFloat = 34
    #else
    private var width: CGFloat = 44
    private var height: CGFloat = 44
    #endif
}
