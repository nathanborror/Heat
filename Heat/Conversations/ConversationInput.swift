import SwiftUI
import SwiftData
import OSLog
import PhotosUI
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationInput", category: "Heat")

struct ConversationInput: View {
    @Environment(ConversationViewModel.self) var conversationViewModel
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]
    
    @State var imagePickerViewModel: ImagePickerViewModel
    @State var content: String
    @State var command: String
    @State var isShowingPhotos: Bool
    
    @FocusState var isFocused: Bool
    
    init(imagePickerViewModel: ImagePickerViewModel = .init(), content: String = "", command: String = "") {
        self.imagePickerViewModel = imagePickerViewModel
        self.content = content
        self.command = command
        self.isShowingPhotos = false
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack {
                
                // Attached images
                if !imagePickerViewModel.imagesSelected.isEmpty {
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
                
                // Input field with buttons
                HStack(alignment: .bottom, spacing: 0) {
                    
                    // Command menu
                    if command.isEmpty {
                        Menu {
                            Button(action: { isShowingPhotos = true }) {
                                Label("Attach Photo", systemImage: "photo")
                            }
                            .keyboardShortcut("1", modifiers: .command)
                            Button(action: { command = "imagine" }) {
                                Label("Imagine", systemImage: "paintpalette")
                            }
                            .keyboardShortcut("2", modifiers: .command)
                            Button(action: { command = "summarize" }) {
                                Label("Summarize", systemImage: "doc.text.magnifyingglass")
                            }
                            .keyboardShortcut("3", modifiers: .command)
                            Button(action: { command = "search" }) {
                                Label("Search", systemImage: "magnifyingglass")
                            }
                            .keyboardShortcut("4", modifiers: .command)
                        } label: {
                            Image(systemName: "plus")
                                .modifier(ConversationInlineButtonModifier())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Selected command
                    if !command.isEmpty {
                        HStack {
                            Text(command)
                            Button(action: { command = "" }) {
                                Image(systemName: "xmark")
                                    .imageScale(.small)
                                    .opacity(0.5)
                            }
                            .buttonStyle(.plain)
                        }
                        #if os(macOS)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 8))
                        .padding(.bottom, 3)
                        .padding(.leading, 3)
                        .padding(.trailing, 8)
                        #else
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 6))
                        .padding(.bottom, 5)
                        .padding(.horizontal, 5)
                        #endif
                    }
                    
                    // Text input
                    TextField("Message", text: $content, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.vertical, verticalPadding)
                        .padding(.trailing, showInputPadding ? 16 : 0)
                        .frame(minHeight: minHeight)
                        .focused($isFocused)
                        #if os(macOS)
                        .onSubmit(handleSubmit)
                        #endif
                    
                    // Speech to text
                    if showInlineControls {
                        Button(action: handleSpeak) {
                            Image(systemName: "waveform")
                                .modifier(ConversationInlineButtonModifier())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .background(.primary.opacity(0.05))
            .clipShape(.rect(cornerRadius: 10))
            
            if showStopGenerating {
                Button(action: handleStop) {
                    Image(systemName: "stop.fill")
                        .modifier(ConversationButtonModifier())
                }
                .buttonStyle(.plain)
            } else if showSubmit {
                Button(action: handleSubmit) {
                    Image(systemName: "arrow.up")
                        .modifier(ConversationButtonModifier())
                }
                .buttonStyle(.plain)
            }
        }
        .photosPicker(isPresented: $isShowingPhotos, selection: $imagePickerViewModel.imagesPicked, maxSelectionCount: 3, matching: .images, photoLibrary: .shared())
        #if !os(macOS)
        .background(.background)
        #endif
    }
    
    func handleSubmit() {
        // TODO:
//        defer { clear() }
//        
//        // Create conversation if one doesn't already exist
//        if conversationViewModel.conversationID == nil {
//            conversationViewModel.newConversation()
//        }
//        
//        // Check for command
//        switch command {
//        case "imagine":
//            handleImagine(content)
//            return
//        case "summarize":
//            handleSummarize(content)
//            return
//        case "search":
//            handleSearch(content)
//            return
//        default:
//            break
//        }
//        
//        // Handle vision prompt if exists
//        if hasVisionAsset || !imagePickerViewModel.imagesSelected.isEmpty {
//            handleVision(content); return
//        }
//        
//        // Ignore empty content
//        guard !content.isEmpty else { return }
//        
//        do {
//            try conversationViewModel.generate(content, context: memories.map { $0.content })
//        } catch let error as KitError {
//            conversationViewModel.error = error
//        } catch {
//            logger.warning("failed to submit: \(error)")
//        }
    }
    
    func handleVision(_ content: String) {
        // TODO:
//        do {
//            let images = imagePickerViewModel.imagesSelected.map {
//                // Resize image so we're not sending huge amounts of data to the services.
//                $0.image?.resize(to: .init(width: 512, height: 512))
//            }.compactMap { $0 }
//            try conversationViewModel.generate(content, images: images)
//        } catch let error as KitError {
//            conversationViewModel.error = error
//        } catch {
//            logger.warning("failed to submit: \(error)")
//        }
//        clear()
    }
    
    func handleImagine(_ content: String) {
        // TODO:
//        do {
//            try conversationViewModel.generateImage(content)
//        } catch let error as KitError {
//            conversationViewModel.error = error
//        } catch {
//            logger.warning("failed to submit: \(error)")
//        }
//        clear()
    }
    
    func handleSummarize(_ content: String) {
//        Task {
//            do {
//                if let markdown = try await WebBrowseSession.shared.generateMarkdown(for: content) {
//                    try conversationViewModel.generateSummary(url: content, markdown: markdown)
//                } else {
//                    logger.error("Failed to generate markdown")
//                }
//            } catch let error as KitError {
//                conversationViewModel.error = error
//            } catch {
//                logger.error("Failed to fetch: \(error)")
//            }
//        }
//        clear()
    }
    
    func handleSearch(_ content: String) {
        Task {
            do {
                let resp = try await WebSearchSession.shared.search(query: content)
                print(resp)
            } catch {
                logger.error("Failed to search: \(error)")
            }
        }
        clear()
    }
    
    func handleSpeak() {
        logger.debug("not implemented")
    }
    
    func handleStop() {
        // TODO:
//        conversationViewModel.generateStop()
    }
    
    private func clear() {
        content = ""
        command = ""
        imagePickerViewModel.removeAll()
    }
    
    private var hasVisionAsset: Bool {
        return false
        // TODO:
//        let visible = conversationViewModel.messages.filter { $0.kind != .instruction }
//        let message = visible.first { message in
//            let attachment = message.attachments.first { attachment in
//                switch attachment {
//                case .agent, .automation, .component, .file:
//                    return false
//                case .asset(let asset):
//                    return asset.noop == false
//                }
//            }
//            return attachment != nil
//        }
//        return message != nil
    }
    
    private var showInlineControls: Bool    { content.isEmpty }
    private var showInputPadding: Bool      { !content.isEmpty }
    // TODO: 
//    private var showStopGenerating: Bool    { (conversationViewModel.conversation?.state ?? .none) != .none }
    private var showStopGenerating = false
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
            .background(.tint)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 10))
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
                    //.clipShape(.rect(cornerRadius: 10))
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
            .foregroundStyle(.regularMaterial)
            .shadow(color: .primary.opacity(0.25), radius: 5)
        }
    }
}
