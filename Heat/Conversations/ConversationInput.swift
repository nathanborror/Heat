import SwiftUI
import OSLog
import PhotosUI
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationInput", category: "Heat")

struct ConversationInput: View {
    @Environment(ConversationViewModel.self) var conversationViewModel

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
                if let image = imagePickerViewModel.image {
                    ConversationInputImage(image: image)
                        .environment(imagePickerViewModel)
                        .padding(.top)
                        .padding(.leading, showInputPadding ? 16 : 0)
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
                        .focusable()
                        .textFieldStyle(.plain)
                        .padding(.vertical, verticalPadding)
                        .padding(.trailing, showInputPadding ? 16 : 0)
                        .frame(minHeight: minHeight)
                        .focused($isFocused)
                        #if os(macOS)
                        .onSubmit(handleSubmit)
                        #endif
                    
                    // Audio input
                    if showInlineControls {
                        Button(action: handleSpeak) {
                            Image(systemName: "waveform")
                                .modifier(ConversationInlineButtonModifier())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(.primary.opacity(0.05))
                .clipShape(.rect(cornerRadius: 10))
            }
            
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
        .photosPicker(isPresented: $isShowingPhotos, selection: $imagePickerViewModel.imageSelection, matching: .images, photoLibrary: .shared())
        #if !os(macOS)
        .background(.background)
        #endif
    }
    
    func handleSubmit() {
        // Create conversation if one doesn't already exist
        if conversationViewModel.conversationID == nil {
            conversationViewModel.newConversation()
        }
        
        switch command {
        case "imagine":
            handleImagine(content)
            return
        case "summarize":
            handleSummarize(content)
            return
        case "search":
            handleSearch(content)
            return
        default:
            break
        }
        
        // Handle vision prompt if exists
        if hasVisionAsset || imagePickerViewModel.image != nil {
            handleVision(content)
            return
        }
        
        // Ignore empty content
        guard !content.isEmpty else { return }
        
        do {
            try conversationViewModel.generate(content)
        } catch let error as HeatKitError {
            conversationViewModel.error = error
        } catch {
            logger.warning("failed to submit: \(error)")
        }
        clear()
    }
    
    func handleVision(_ content: String) {
        do {
            if let data = imagePickerViewModel.image?.resize(to: .init(width: 512, height: 512)) {
                try conversationViewModel.generate(content, images: [data])
            } else {
                try conversationViewModel.generate(content, images: [])
            }
        } catch let error as HeatKitError {
            conversationViewModel.error = error
        } catch {
            logger.warning("failed to submit: \(error)")
        }
        clear()
    }
    
    func handleImagine(_ content: String) {
        do {
            try conversationViewModel.generateImage(content)
        } catch let error as HeatKitError {
            conversationViewModel.error = error
        } catch {
            logger.warning("failed to submit: \(error)")
        }
        clear()
    }
    
    func handleSummarize(_ content: String) {
        guard let url = URL(string: content) else {
            print("failed to make URL")
            return
        }
        Task {
            do {
                let markdown = try await BrowserManager.shared.fetch(url: url, urlMode: .omit, hideJSONLD: true, hideImages: true)
                try conversationViewModel.generateSummary(url: url.absoluteString, markdown: markdown)
            } catch let error as HeatKitError {
                conversationViewModel.error = error
            } catch {
                logger.error("Failed to fetch: \(error)")
            }
        }
        clear()
    }
    
    func handleSearch(_ content: String) {
        Task {
            do {
                let resp = try await SearchManager.shared.search(query: content)
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
        conversationViewModel.generateStop()
    }
    
    private func clear() {
        content = ""
        command = ""
        //self.imagePickerViewModel.removeAll()
        imagePickerViewModel.imageSelection = nil
    }
    
    private var hasVisionAsset: Bool {
        let message = conversationViewModel.messagesVisible.first { message in
            let attachment = message.attachments.first { attachment in
                switch attachment {
                case .agent, .automation, .component:
                    return false
                case .asset(let asset):
                    return asset.noop == false
                }
            }
            return attachment != nil
        }
        return message != nil
    }
    
    private var showInlineControls: Bool    { content.isEmpty }
    private var showInputPadding: Bool      { !content.isEmpty }
    private var showStopGenerating: Bool    { (conversationViewModel.conversation?.state ?? .none) != .none }
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
    
    #if os(macOS)
    let image: NSImage
    #else
    let image: UIImage
    #endif
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            imageView
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(.rect(cornerRadius: 10))
         
            Button {
                imagePickerViewModel.imageSelection = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.medium)
                    .padding(4)
            }
            .foregroundStyle(.regularMaterial)
            .shadow(color: .primary.opacity(0.25), radius: 5)
        }
    }
    
    private var imageView: Image {
        #if os(macOS)
        Image(nsImage: image)
        #else
        Image(uiImage: image)
        #endif
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ConversationInput()
        }
        .padding()
    }
    .environment(ConversationViewModel(store: Store.preview))
}
