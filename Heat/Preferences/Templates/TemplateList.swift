import SwiftUI
import HeatKit

struct TemplateList: View {
    @Environment(TemplatesProvider.self) var templatesProvider
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                NavigationLink("Add Template") {
                    TemplateForm(template: .empty)
                }
            }
            Section {
                ForEach(templatesProvider.templates) { template in
                    NavigationLink(template.name) {
                        TemplateForm(template: template)
                    }
                    .swipeActions {
                        Button(role: .destructive, action: { handleDelete(template) }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Templates")
        .appFormStyle()
    }
    
    func handleDelete(_ template: Template) {
        Task { try await templatesProvider.delete(template.id)}
    }
}
