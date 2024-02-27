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
                        }
                        Spacer()
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
            .environment(store)
        }
    }
}

#Preview("Services") {
    NavigationStack {
        ServiceList()
    }
    .environment(Store.preview)
}
