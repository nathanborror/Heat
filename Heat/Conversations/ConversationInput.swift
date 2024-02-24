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
    @State var isShowingPhotos: Bool
    
    @FocusState var isFocused: Bool
    
    init(content: String = "", command: String = "") {
        self.imagePickerViewModel = .init()
        self.content = content
        self.isShowingPhotos = false
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 0) {
                Menu {
                    Button(action: { isShowingPhotos = true }) {
                        Label("Attach Photo", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "plus")
                        .modifier(ConversationInlineButtonModifier())
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let image = imagePickerViewModel.image {
                        ConversationInputImage(image: image)
                            .environment(imagePickerViewModel)
                            .padding(.top)
                            .padding(.leading, showInputPadding ? 16 : 0)
                    }
                    TextField("Message", text: $content, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.vertical, verticalPadding)
                        .padding(.trailing, showInputPadding ? 16 : 0)
                        .frame(minHeight: minHeight)
                        .focused($isFocused)
                        #if os(macOS)
                        .onSubmit(handleSubmit)
                        #endif
                }
                
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
            
            if showStopGenerating {
                Button(action: handleStop) {
                    Image(systemName: "stop.fill")
                        .modifier(ConversationButtonModifier())
                }
                .buttonStyle(.plain)
            }
            if showSubmit {
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
        
        // Ignore empty content
        guard !content.isEmpty else { return }
        
        // Create conversation if one doesn't already exist
        if conversationViewModel.conversationID == nil {
            conversationViewModel.newConversation()
        }
        
        // Handle vision prompt if exists
        if hasVisionAsset || imagePickerViewModel.image != nil {
            handleVisionSubmit()
            return
        }
        
        do {
            try conversationViewModel.generate(content)
        } catch let error as HeatKitError {
            conversationViewModel.error = error
        } catch {
            logger.warning("failed to submit: \(error)")
        }
        content = ""
        imagePickerViewModel.imageSelection = nil
    }
    
    func handleVisionSubmit() {
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
        content = ""
        imagePickerViewModel.imageSelection = nil
    }
    
    func handleStop() {
        conversationViewModel.generateStop()
    }
    
    func handleSpeak() {}
    
    private var hasVisionAsset: Bool {
        let message = conversationViewModel.humanVisibleMessages.first { message in
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
