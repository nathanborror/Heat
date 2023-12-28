import SwiftUI

@Observable
final class MessageInputViewState {
    enum State: Equatable {
        case resting
        case focused
        case drafting
        case streaming
    }
    
    private(set) var current: State = .resting
    private(set) var previous: State? = nil
    
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

struct MessageInput: View {
    @Environment(MessageInputViewState.self) var viewState
    
    @Binding var text: String
    
    var submit: (String) -> Void
    var stop: () -> Void
    
    var body: some View {
        HStack {
            MessageField(text: $text)
                .onSubmit(handleSubmitFromKeyboard)
            
            switch viewState.current {
            case .drafting:
                MessageSubmitButton(action: handleSubmit)
            case .streaming:
                MessageStopButton(action: handleStop)
            default:
                EmptyView()
            }
        }
        .environment(viewState)
        .padding(.horizontal)
    }
    
    func handleSubmit() {
        guard !text.isEmpty else { return }
        
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

// MARK: Private

private struct MessageField: View {
    @Environment(MessageInputViewState.self) var viewState
    
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
                viewState.change(.drafting)
            }
        }
        .onChange(of: focused) { _, newValue in
            if newValue {
                viewState.change(text.isEmpty ? .focused : .drafting)
            } else {
                viewState.change(text.isEmpty ? .resting : .drafting)
            }
        }
        .onChange(of: viewState.current) { _, newValue in
            switch newValue {
            case .resting:
                focused = false
            case .focused, .drafting:
                focused = true
            case .streaming:
                break
            }
        }
    }
    
    #if os(macOS)
    private let minHeight: CGFloat = 32
    #else
    private let minHeight: CGFloat = 44
    #endif
}

private struct MessageSubmitButton: View {
    @Environment(MessageInputViewState.self) var viewState
    
    var action: () -> Void
    
    var body: some View {
        MessageActionButton(symbol: "arrow.up", action: action)
            .fontWeight(.bold)
            .tint(.secondary)
            .background(.tint)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 22))
            .frame(width: 38)
    }
}

private struct MessageStopButton: View {
    @Environment(MessageInputViewState.self) var viewState
    
    var action: () -> Void
    
    var body: some View {
        MessageActionButton(symbol: "stop.fill", action: action)
            .fontWeight(.bold)
            .background(.tint.opacity(0.2))
            .foregroundStyle(.tint)
            .clipShape(.rect(cornerRadius: 22))
            .frame(width: 38)
    }
}

private struct MessageActionButton: View {
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
