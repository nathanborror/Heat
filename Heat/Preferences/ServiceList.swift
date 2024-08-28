import SwiftUI
import GenKit
import HeatKit

struct ServiceList: View {
    @Environment(PreferencesProvider.self) var preferencesProvider
    
    @State var services: [Service] = []
    @State var selectedService: Service?
    
    var body: some View {
        Form {
            ForEach(services) { service in
                Section {
                    LabeledContent("Chat", value: service.preferredChatModel ?? "None")
                    LabeledContent("Image", value: service.preferredImageModel ?? "None")
                    LabeledContent("Vision", value: service.preferredVisionModel ?? "None")
                    LabeledContent("Tools", value: service.preferredToolModel ?? "None")
                    LabeledContent("Summarization", value: service.preferredSummarizationModel ?? "None")
                } header: {
                    HStack {
                        Text(service.name)
                        Spacer()
                        Button {
                            selectedService = service
                        } label: {
                            Text("Edit")
                                .font(.footnote)
                        }
                    }
                }
            }
        }
        .navigationTitle("Services")
        .appFormStyle()
        .sheet(item: $selectedService) { service in
            NavigationStack {
                ServiceForm(service: service)
            }
        }
        .onAppear {
            services = preferencesProvider.services
        }
    }
}

#Preview {
    ServiceList(services: [
        Defaults.openAI,
        Defaults.anthropic,
        Defaults.mistral,
    ])
}
