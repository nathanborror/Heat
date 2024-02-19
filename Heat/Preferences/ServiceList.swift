import SwiftUI
import GenKit
import HeatKit

struct ServiceList: View {
    @Environment(Store.self) private var store
    
    @State private var selectedService: Service? = nil
    
    var body: some View {
        Form {
            Section {
                ForEach(store.preferences.services) { service in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(service.name)
                            if let text = supportText(for: service) {
                                Text(text)
                                    .lineLimit(1)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            if service.missingHost {
                                Text("Host missing")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                            if service.missingToken {
                                Text("Token missing")
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                        }
                        Spacer()
                        Button("Edit") {
                            selectedService = service
                        }
                    }
                }
            }
            Section {
                Button("Add Service", action: { self.selectedService = .init(id: "", name: "") })
            }
        }
        .navigationTitle("Services")
        .sheet(item: $selectedService) { service in
            NavigationStack {
                ServiceForm(service: service)
            }
            .environment(store)
        }
    }
    
    func supportText(for service: Service) -> String? {
        let supports = [
            (service.supportsChats) ? "Chats" : nil,
            (service.supportsImages) ? "Images" : nil,
            (service.supportsEmbeddings) ? "Embeddings" : nil,
            (service.supportsTranscriptions) ? "Transcriptions" : nil,
            (service.supportsTools) ? "Tools" : nil,
            (service.supportsVision) ? "Vision" : nil,
            (service.supportsSpeech) ? "Speech" : nil,
        ].compactMap { $0 }
        if supports.isEmpty { return nil }
        return supports.joined(separator: ", ")
    }
}

#Preview("Services") {
    NavigationStack {
        ServiceList()
    }
    .environment(Store.preview)
}
