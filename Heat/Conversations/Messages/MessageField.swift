import SwiftUI
import OSLog
import PhotosUI
import GenKit
import HeatKit

private let logger = Logger(subsystem: "MessageField", category: "App")

struct MessageField: View {
    @Environment(AppState.self) var state
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.colorScheme) var colorScheme

    typealias ActionHandler = (String, [URL], Command) -> Void
    typealias AgentHandler = (Agent) -> Void

    let action: ActionHandler
    let agentAction: AgentHandler?

    enum Command: String {
        case text
        case imagine
    }

    @State private var imagePickerViewModel = ImagePickerViewModel()
    @State private var content = ""
    @State private var command: Command = .text
    @State private var showingPhotos = false
    @State private var showingAgent: Agent? = nil
    @State private var showingStop = false

    @FocusState private var isFocused: Bool

    init(action: @escaping ActionHandler, agent: AgentHandler? = nil) {
        self.action = action
        self.agentAction = agent
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack {

                // Attached images
                if !imagePickerViewModel.imagesSelected.isEmpty {
                    attachments
                }

                // Input field with buttons
                HStack(alignment: .bottom, spacing: 0) {

                    // Command menu
                    if command == .text {
                        commandMenu
                    }

                    // Selected command
                    if command != .text {
                        commandSelected
                    }

                    // Text input
                    TextField("Message", text: $content, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.vertical, verticalPadding)
                        .padding(.trailing, showInputPadding ? 16 : 0)
                        .frame(minHeight: minHeight)
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
                }
            }
            .background(.primary.opacity((colorScheme == .dark) ? 0.1 : 0.05))
            .clipShape(.rect(cornerRadius: 10))

            if showingStop {
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
        .photosPicker(isPresented: $showingPhotos, selection: $imagePickerViewModel.imagesPicked, maxSelectionCount: 3, matching: .images, photoLibrary: .shared())
        .sheet(item: $showingAgent) { agent in
            NavigationStack {
                MessageFieldAgent(agent: agent) { agent in
                    agentAction?(agent)
                }
            }
        }
        .onChange(of: conversationViewModel.conversation?.state) { _, newValue in
            switch newValue {
            case .processing, .streaming, .suggesting:
                showingStop = true
            default:
                showingStop = false
            }
        }
    }

    var attachments: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .bottom) {
                ForEach(imagePickerViewModel.imagesSelected) { selected in
                    ConversationInputImage(id: selected.id, image: selected.image)
                        .environment(imagePickerViewModel)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 8)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    var commandMenu: some View {
        Menu {
            Button(action: { showingPhotos = true }) {
                Label("Attach Photo", systemImage: "photo")
            }
            Button(action: { command = .imagine }) {
                Label("Create Image", systemImage: "paintpalette")
            }
            Menu {
                ForEach(state.agentsProvider.agents.filter { $0.kind == .prompt }) { agent in
                    Button {
                        showingAgent = agent
                    } label: {
                        Text(agent.name)
                    }
                }
            } label: {
                Label("Use Agent", systemImage: "puzzlepiece")
            }
        } label: {
            Image(systemName: "plus")
                .modifier(ConversationInlineButtonModifier())
        }
        .buttonStyle(.plain)
    }

    var commandSelected: some View {
        HStack {
            Text(command.rawValue)
            Button(action: { self.command = .text }) {
                Image(systemName: "xmark")
                    .imageScale(.small)
                    .opacity(0.5)
            }
            .buttonStyle(.plain)
        }
        #if os(macOS)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .foregroundStyle(.white)
        .background(.tint, in: .rect(cornerRadius: 8))
        .padding(.bottom, 3)
        .padding(.leading, 3)
        .padding(.trailing, 8)
        #else
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundStyle(.white)
        .background(.tint, in: .rect(cornerRadius: 6))
        .padding(.bottom, 5)
        .padding(.horizontal, 5)
        #endif
    }

    func handleSubmit() async throws {
        defer { clear() }

        // Check for command
        switch command {
        case .imagine:
            action(content, [], .imagine)
            return
        default:
            break
        }

        // If there are images in the image picker, return a vision action
        if !imagePickerViewModel.imagesSelected.isEmpty {
            // Resize image so we're not sending huge amounts of data to the services.
            let images = imagePickerViewModel.imagesSelected.map {
                $0.image?.resizedToMaxDimension(1568)?.jpegData(compressionQuality: 0.8)
            }.compactMap { $0 }

            var imageURLs = [URL]()
            for imageData in images {
                let filename = "\(String.id).jpg"
                let url = URL.documentsDirectory.appending(path: "images").appending(path: filename)
                try imageData.write(to: url, options: .atomic, createDirectories: true)
                imageURLs.append(url)
            }

            action(content, imageURLs, .text)
            return
        }

        // Return regular text action
        action(content, [], command)
        clear()
    }

    func handleStop() {
        conversationViewModel.cancel()
    }

    private func clear() {
        content = ""
        command = .text
        imagePickerViewModel.removeAll()
    }

    private var showInputPadding: Bool      { !content.isEmpty }
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
            .background(.tint, in: .rect(cornerRadius: 10))
            .padding(.vertical, 2)
    }

    #if os(macOS)
    private var width: CGFloat = 32
    private var height: CGFloat = 32
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

struct ConversationInputImage: View {
    @Environment(ImagePickerViewModel.self) var imagePickerViewModel

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
