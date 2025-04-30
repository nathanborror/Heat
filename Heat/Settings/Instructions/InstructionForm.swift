import SwiftUI
import OSLog
import SharedKit
import GenKit
import HeatKit

struct InstructionForm: View {
    @Environment(AppState.self) var state

    let fileID: String?

    @State private var selectedTab: Tab = .profile
    @State private var newToolName: String = ""
    @State private var isShowingAlert = false

    enum Tab: String, CaseIterable {
        case profile = "Profile"
        case instructions = "Instructions"
        case tools = "Tools"
    }

    init(_ fileID: String? = nil) {
        self.fileID = fileID
    }

    var body: some View {
        #if os(macOS)
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .padding()
                    .id(fileID)
                    .tag(tab)
                    .tabItem {
                        Text(tab.rawValue)
                    }
            }
        }
        .tabViewStyle(.tabBarOnly)
        .navigationTitle("Instruction")
        #else
        VStack {
            Picker("Select item", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            tabContent(for: selectedTab)
        }
        #endif
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        VStack(alignment: .leading) {
            switch tab {
            case .profile:
                InstructionProfileForm(fileID)
            case .instructions:
                if let fileID {
                    InstructionTextForm(fileID)
                }
            case .tools:
                if let fileID {
                    InstructionToolsForm(fileID)
                }
            }
        }
    }
}

struct InstructionProfileForm: View {
    @Environment(AppState.self) var state

    let fileID: String?

    @State var name = ""
    @State var kind = Instruction.Kind.assistant

    init(_ fileID: String? = nil) {
        self.fileID = fileID
    }

    var body: some View {
        Form {
            if let fileID {
                TextField("ID", text: .constant(fileID))
                    .disabled(true)
            }
            
            TextField("Name", text: $name)

            Picker("Kind", selection: $kind) {
                ForEach(Instruction.Kind.allCases, id: \.self) {
                    Text($0.rawValue.capitalized).tag($0)
                }
            }
        }
        .onAppear {
            handleAppear()
        }
        .onDisappear {
            handleDisappear()
        }
    }

    func handleAppear() {
        guard let fileID else { return }
        Task {
            do {
                let data = try await API.shared.fileData(fileID)
                let instruction = try JSONDecoder().decode(Instruction.self, from: data)
                kind = instruction.kind

                let file = try API.shared.file(fileID)
                name = file.name ?? ""
            } catch {
                print(error)
            }
        }
    }

    func handleDisappear() {
        guard let fileID else { return }
        Task {
            do {
                // Update file data
                let data = try await API.shared.fileData(fileID)
                var instruction = try JSONDecoder().decode(Instruction.self, from: data)
                instruction.kind = kind
                try await API.shared.fileUpdate(fileID, object: instruction)

                // Update metadata
                var file = try API.shared.file(fileID)
                file.name = name.isEmpty ? nil : name
                try await API.shared.fileUpdate(file)
            } catch {
                print(error)
            }
        }
    }
}

struct InstructionToolsForm: View {
    @Environment(AppState.self) var state

    let fileID: String

    @State var toolIDs: Set<String> = []

    init(_ fileID: String) {
        self.fileID = fileID
    }

    var body: some View {
        VStack {
            List {
                ForEach(Array(toolIDs.sorted(by: <)), id: \.self) { toolID in
                    Text(toolID)
                        .swipeActions {
                            Button(role: .destructive) {
                                toolIDs.remove(toolID)
                            } label: {
                                Label("Trash", systemImage: "trash")
                            }
                        }
                }
            }
            #if os(macOS)
            .listStyle(.bordered)
            #endif

            Spacer()

            HStack {
                ControlGroup {
                    Button(action: {}) {
                        Label("Decrease", systemImage: "minus")
                    }
                    .disabled(true)

                    Button(action: {}) {
                        Label("Increase", systemImage: "plus")
                    }
                }
                .frame(width: 60)
                Spacer()
            }
        }
        .onAppear {
            handleAppear()
        }
        .onDisappear {
            handleDisappear()
        }
    }

    func handleAppear() {
        Task {
            do {
                let data = try await API.shared.fileData(fileID)
                let instruction = try JSONDecoder().decode(Instruction.self, from: data)
                toolIDs = instruction.toolIDs
            } catch {
                print(error)
            }
        }
    }

    func handleDisappear() {
        Task {
            do {
                let data = try await API.shared.fileData(fileID)
                var instruction = try JSONDecoder().decode(Instruction.self, from: data)
                instruction.toolIDs = toolIDs

                Task {
                    try await API.shared.fileUpdate(fileID, object: instruction)
                }
            } catch {
                print(error)
            }
        }
    }
}

struct InstructionTextForm: View {
    @Environment(AppState.self) var state

    let fileID: String

    @State var instructions: String = ""

    init(_ fileID: String) {
        self.fileID = fileID
    }

    var body: some View {
        VStack {
            TextEditor(text: $instructions)
                .overlay {
                    Rectangle()
                        .fill(.clear)
                        .stroke(.separator, lineWidth: 1)
                }
        }
        .onAppear {
            handleAppear()
        }
        .onDisappear {
            handleDisappear()
        }
    }

    func handleAppear() {
        Task {
            do {
                let instruction = try await API.shared.fileData(fileID, type: Instruction.self)
                instructions = instruction.instructions
            } catch {
                print(error)
            }
        }
    }

    func handleDisappear() {
        Task {
            do {
                var instruction = try await API.shared.fileData(fileID, type: Instruction.self)
                instruction.instructions = instructions
                try await API.shared.fileUpdate(fileID, object: instruction)
            } catch {
                print(error)
            }
        }
    }
}

struct InstructionTool: View {
    @Environment(\.dismiss) var dismiss

    @State var text: String = ""

    let action: (String) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Form {
            TextField("Name", text: $text)
                .focused($isFocused)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            handleSubmit()
                        } label: {
                            Text("Done")
                        }
                    }
                }
        }
        .onAppear {
            isFocused = true
        }
    }

    func handleSubmit() {
        action(text.trimmingCharacters(in: .whitespacesAndNewlines))
        text = ""
        dismiss()
    }
}
