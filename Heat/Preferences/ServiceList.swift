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
                NavigationLink {
                    ServiceForm(service: service)
                } label: {
                    HStack {
                        Text(service.name)
                        Spacer()
                        Circle()
                            .fill(statusIndicatorColor(service))
                            .frame(width: 8, height: 8)
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
    
    func statusIndicatorColor(_ service: Service) -> Color {
        switch service.status {
        case .ready:
            .green
        case .unknown:
            .primary.opacity(0.1)
        default:
            .yellow
        }
    }
}
