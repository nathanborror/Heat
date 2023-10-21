import SwiftUI

struct ChatComposerView: View {
    class ViewState: ObservableObject {
        enum State: Equatable {
            case resting
            case focused
            case drafting
            case streaming
        }
        
        @Published private(set) var current: State = .resting
        @Published private(set) var previous: State? = nil
        
        func change(_ state: State) {
            guard state != current else { return }
            previous = current
            current = state
        }
        
        func back() {
            current = previous ?? .resting
            previous = nil
        }
    }
    
    @Binding var text: String
    
    @ObservedObject var state: ViewState
    
    var submit: (String) -> Void
    var stop: () -> Void
    
    var body: some View {
        HStack {
            ComposerInput(state: state, text: $text)
                .onSubmit(handleSubmitFromKeyboard)
            
            switch state.current {
            case .drafting:
                SubmitButton(state: state, action: handleSubmit)
            case .streaming:
                StopButton(state: state, action: handleStop)
            default:
                EmptyView()
            }
        }
        .padding(.horizontal)
    }
    
    func handleSubmit() {
        
        // Clear text before calling submit to prevent a race condition
        // where submit could lead to composer state changes (i.e. Stop / Cancel).
        let content = text
        text = ""
        
        // Adding a very short wait to avoid the race condition mentioned above.
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            submit(content)
        }
    }
    
    func handleStop() {
        stop()
    }
    
    func handleSubmitFromKeyboard() {
        #if os(macOS)
        handleSubmit()
        #endif
    }
}

struct ComposerInput: View {
    @ObservedObject var state: ChatComposerView.ViewState
    @Binding var text: String
    
    @FocusState var focused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                TextField("Aa", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .focused($focused, equals: true)
            }
        }
        .frame(minWidth: 54, minHeight: minHeight)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        }
        .onChange(of: text) { _, newValue in
            if !newValue.isEmpty {
                state.change(.drafting)
            } else {
                state.change(.resting)
            }
        }
        .onChange(of: focused) { _, newValue in
            if newValue {
                state.change(text.isEmpty ? .focused : .drafting)
            } else {
                state.change(text.isEmpty ? .resting : .drafting)
            }
        }
    }
    
    #if os(macOS)
    private let minHeight: CGFloat = 32
    #else
    private let minHeight: CGFloat = 44
    #endif
}

struct SubmitButton: View {
    @ObservedObject var state: ChatComposerView.ViewState
    var action: () -> Void
    
    var body: some View {
        ComposerActionButton(symbol: "arrow.up", action: action)
            .fontWeight(.bold)
            .tint(.secondary)
            .background(.tint)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 22))
            .frame(width: 38)
    }
}

struct StopButton: View {
    @ObservedObject var state: ChatComposerView.ViewState
    var action: () -> Void
    
    var body: some View {
        ComposerActionButton(symbol: "stop.fill", action: action)
            .fontWeight(.bold)
            .background(.tint.opacity(0.2))
            .foregroundStyle(.tint)
            .clipShape(.rect(cornerRadius: 22))
            .frame(width: 38)
    }
}

struct ComposerActionButton: View {
    let symbol: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Image(systemName: symbol)
                Spacer()
            }
        }
        .buttonStyle(.borderless)
        .frame(minHeight: minHeight)
    }
    
    #if os(macOS)
    private let minHeight: CGFloat = 32
    #else
    private let minHeight: CGFloat = 38
    #endif
}
