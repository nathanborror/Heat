import SwiftUI
import GenKit
import HeatKit

struct ServiceList: View {
    @State private var selectedService: Service? = nil
    
    var body: some View {
        Form {
            Section {
                ForEach(PreferencesProvider.shared.preferences.services) { service in
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
