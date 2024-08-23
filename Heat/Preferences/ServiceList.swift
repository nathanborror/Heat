import SwiftUI
import GenKit
import HeatKit

struct ServiceList: View {
    @Environment(PreferencesProvider.self) var preferencesProvider
    
    @State var selectedService: Service?
    
    var body: some View {
        Form {
            Section {
                ForEach(preferencesProvider.services) { service in
                    HStack {
                        Text(service.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Edit") {
                            selectedService = service
                        }
                    }
                }
            }
        }
        .navigationTitle("Services")
        .sheet(item: $selectedService) { service in
            NavigationStack {
                ServiceForm(service: service)
            }
        }
    }
}
