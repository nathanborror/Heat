import SwiftUI
import OSLog
import PhotosUI
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationInput", category: "Heat")

struct ConversationInput: View {
    @Environment(ConversationViewModel.self) var conversationViewModel

    @State var imagePickerViewModel = ImagePickerViewModel()
    @State var content = ""
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 0) {
                if showInlineControls {
                    PhotosPicker(selection: $imagePickerViewModel.imageSelection, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "plus")
                            .modifier(ConversationInlineButtonModifier())
                    }
                    .buttonStyle(.plain)
                }
                
                // TODO: Clean this up
                VStack(alignment: .leading, spacing: 4) {
                    if let image = imagePickerViewModel.image {
                        #if os(macOS)
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: 10))
                            .padding(.top)
                            .padding(.leading, showInputPadding ? 16 : 0)
                        #else
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: 10))
                            .padding(.top)
                            .padding(.leading, showInputPadding ? 16 : 0)
                        #endif
                    }
                    TextField("Message", text: $content, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.vertical, verticalPadding)
                        .padding(.horizontal, showInputPadding ? 16 : 0)
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
            }
            if showSubmit {
                Button(action: handleSubmit) {
                    Image(systemName: "arrow.up")
                        .modifier(ConversationButtonModifier())
                }
                .buttonStyle(.plain)
            }
        }
        #if os(iOS)
        .background(.background)
        #endif
        .onOpenURL { url in
            guard let host = url.host() else { return }
            guard host == "focus" else { return }
            isFocused = true
        }
        .onAppear {
            isFocused = true
        }
    }
    
    func handleSubmit() {
        guard !content.isEmpty else { return }
        if conversationViewModel.conversationID == nil {
            conversationViewModel.newConversation()
        }
        
        let message = conversationViewModel.humanVisibleMessages.first(where: { message in
            let attachment = message.attachments.first { attachment in
                switch attachment {
                case .agent: return false
                case .asset(let asset): return asset.noop == false
                }
            }
            return attachment != nil
        })
        
        let isVisionRequest = message != nil || imagePickerViewModel.image != nil
        
        do {
            if isVisionRequest {
                if let data = imagePickerViewModel.image?.resize(to: .init(width: 512, height: 512)) {
                    try conversationViewModel.generate(content, images: [data])
                } else {
                    try conversationViewModel.generate(content, images: [])
                }
            } else {
                try conversationViewModel.generate(content)
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

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ConversationInput()
                .environment(ConversationViewModel(store: Store.preview))
//            ConversationInput(viewModel: .init(text: "Lorem ipsum dolor sit amet"))
//            ConversationInput(viewModel: .init(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."))
//            ConversationInput(viewModel: .init(isGenerating: true))
        }
        .padding()
    }
}
