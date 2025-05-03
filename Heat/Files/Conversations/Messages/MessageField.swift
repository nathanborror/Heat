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
    @State private var photoPickerModel = PhotoPickerModel()
    @State private var showingPhotoPicker = false

    @FocusState private var isFocused: Bool

    init(action: @escaping ActionHandler) {
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            if !photoPickerModel.selections.isEmpty {
                ScrollView(.horizontal) {
                    HStack(alignment: .bottom) {
                        ForEach(photoPickerModel.selections) { selected in
                            MessageFieldPhoto(id: selected.id, image: selected.photo)
                                .environment(photoPickerModel)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }

            Divider()
            HStack(alignment: .bottom, spacing: 0) {
                Menu {
                    Button("Attach Image") {
                        showingPhotoPicker = true
                    }
                    Divider()
                    ForEach(state.instructions) { file in
                        if let instruction = try? state.file(Instruction.self, fileID: file.id), instruction.kind == .template {
                            Button(file.name ?? "Untitled") {
                                instructionFile = file
                            }
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                        .tint(.primary)
                        .frame(width: inlineButtonSize.width, height: inlineButtonSize.height)
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
                            .fontWeight(.medium)
                            .frame(width: primaryButtonSize.width, height: primaryButtonSize.height)
                            .foregroundStyle(.white)
                            .background(.tint, in: .rect(cornerRadius: 8))
                            .padding(.vertical, 2)
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
                            .fontWeight(.medium)
                            .frame(width: primaryButtonSize.width, height: primaryButtonSize.height)
                            .foregroundStyle(.white)
                            .background(.tint, in: .rect(cornerRadius: 8))
                            .padding(.vertical, 2)
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
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $photoPickerModel.items,
                maxSelectionCount: 3,
                selectionBehavior: .ordered,
                matching: .images,
                photoLibrary: .shared()
            )
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
    private var inlineButtonSize = CGSize(width: 34, height: 34)
    private var primaryButtonSize = CGSize(width: 30, height: 30)
    #else
    private var minHeight: CGFloat = 44
    private var verticalPadding: CGFloat = 11
    private var inlineButtonSize = CGSize(width: 44, height: 44)
    private var primaryButtonSize = CGSize(width: 40, height: 40)
    #endif
}

struct MessageFieldPhoto: View {
    @Environment(PhotoPickerModel.self) var imagePickerViewModel

    let id: String
    #if os(macOS)
    let image: NSImage?
    #else
    let image: UIImage?
    #endif

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(.rect(cornerRadius: 10))
                #else
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(.rect(cornerRadius: 10))
                #endif
            } else {
                Rectangle()
                    .fill(.secondary)
                    .frame(width: 100, height: 100)
                    .clipShape(.rect(cornerRadius: 10))
            }

            Button {
                imagePickerViewModel.remove(id: id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.medium)
                    .padding(4)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.regularMaterial)
            .shadow(color: .primary.opacity(0.25), radius: 5)
        }
    }
}
