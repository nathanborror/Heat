import SwiftUI
import OSLog
import SharedKit
import GenKit
import HeatKit

struct GeneralForm: View {
    @Environment(AppState.self) var state

    @State private var selectedTab: Tab = .profile
    @State private var newToolName: String = ""
    @State private var isShowingAlert = false

    enum Tab: String, CaseIterable {
        case profile = "Profile"
    }

    var body: some View {
        #if os(macOS)
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .padding()
                    .tag(tab)
                    .tabItem {
                        Text(tab.rawValue)
                    }
            }
        }
        .tabViewStyle(.tabBarOnly)
        .navigationTitle("Account")
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
        switch tab {
        case .profile: ConfigUserForm()
        }
    }
}

struct ConfigUserForm: View {
    @Environment(AppState.self) var state

    @State var name: String
    @State var bio: String
    @State var location: String
    @State var birthdate: Date?

    private var defaultDate: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? .now
    }

    init() {
        self.name = ""
        self.bio = ""
        self.location = ""
        self.birthdate = defaultDate
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("Location", text: $location)
                    .autocorrectionDisabled(false)
                TextField("Bio", text: $bio, axis: .vertical)
            }

            Section {
                Toggle("Show Birth Date", isOn: Binding(
                    get: { birthdate != nil },
                    set: { if !$0 { birthdate = nil } else { birthdate = defaultDate } }
                ))

                if birthdate != nil {
                    DatePicker(
                        "Birthday",
                        selection: Binding(
                            get: { birthdate ?? defaultDate },
                            set: { birthdate = $0 }
                        ),
                        displayedComponents: [.date]
                    )
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
        print("not implemented")
    }

    func handleDisappear() {
        print("not implemented")
    }
}
