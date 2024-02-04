import SwiftUI
import OSLog
import GenKit
import HeatKit

private let logger = Logger(subsystem: "ConversationInput", category: "Heat")

struct ConversationInput: View {
    @Environment(ConversationViewModel.self) var conversationViewModel

    @State var content = ""
    @FocusState var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 0) {
                if showInlineControls {
                    Button(action: handlePlus) {
                        Image(systemName: "plus")
                            .modifier(ConversationInlineButtonModifier())
                    }
                    .buttonStyle(.plain)
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
        do {
            try conversationViewModel.generate(content)
        } catch let error as HeatKitError {
            conversationViewModel.error = error
        } catch {
            logger.warning("failed to submit: \(error)")
        }
        content = ""
    }
    
    func handlePlus() {}
    
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
