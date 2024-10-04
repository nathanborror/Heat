//#if os(macOS)
//import SwiftUI
//import SwiftData
//import OSLog
//import GenKit
//import HeatKit
//
//private let logger = Logger(subsystem: "LauncherView", category: "App")
//
//struct LauncherView: View {
//    @Environment(\.modelContext) private var modelContext
//    
//    @State private var content = ""
//    @State private var isShowingContent = false
//    @State private var isShowingError = false
//    
//    @Query(sort: \Memory.created, order: .forward) var memories: [Memory]
//    
//    let delay: TimeInterval = 2.0
//    
//    var body: some View {
//        LauncherPanel(isShowingContent: $isShowingContent) {
//            HStack {
//                Image("IconDark")
//                    .resizable()
//                    .frame(width: 32, height: 32)
//                    .opacity(0.1)
//                TextField("Lets go", text: $content, axis: .vertical)
//                    .textFieldStyle(.plain)
//                    .font(.title)
//                    .onSubmit {
//                        Task { try await handleSubmit() }
//                    }
//            }
//            .padding()
//        } content: {
//            ScrollView {
//                VStack(spacing: 0) {
//                    if let message = conversationViewModel.messages.last, message.role == .assistant {
//                        MessageView(message: message)
//                            .font(.title2)
//                    }
//                    if conversationViewModel.conversation?.state == .processing {
//                        TypingIndicator()
//                    }
//                }
//                .padding()
//            }
//            .scrollIndicators(.hidden)
//        }
//        .task {
//            handleInit()
//        }
//    }
//    
//    @MainActor func handleInit() {
//        guard conversationViewModel.conversationID != nil else { return }
//        isShowingContent = true
//    }
//    
//    func handleSubmit() async throws {
//        do {
//            try conversationViewModel.generate(chat: content, context: memories.map { $0.content })
//            isShowingContent = true
//            content = ""
//        } catch {
//            conversationViewModel.error = error
//        }
//    }
//}
//
//struct LauncherPanel<Toolbar: View, Content: View>: View {
//    @Binding var isShowingContent: Bool
//    
//    @ViewBuilder let toolbar: () -> Toolbar
//    @ViewBuilder let content: () -> Content
//    
//    @Environment(\.floatingPanel) var panel
//    
//    var body: some View {
//        
//        VStack(spacing: 0) {
//            toolbar()
//            if isShowingContent {
//                Divider()
//                content()
//            }
//            Spacer(minLength: 0)
//        }
//        .background {
//            VisualEffectView(material: .sidebar)
//        }
//        .frame(
//            minWidth: 512,
//            minHeight: isShowingContent ? 512 : toolbarHeight,
//            idealHeight: isShowingContent ? 512 : toolbarHeight,
//            maxHeight: isShowingContent ? .infinity : toolbarHeight
//        )
//        .clipShape(.rect(cornerRadius: 10))
//    }
//    
//    private let toolbarHeight: CGFloat = 60
//}
//#endif
