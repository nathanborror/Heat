import SwiftUI
import HeatKit

struct TemplateListView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                NavigationLink(destination: { Text("Foo") }, label: { Text("New Template") })
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(store.templates) { template in
                        TemplateTile(
                            template: template,
                            height: proxy.size.width/heightDivisor,
                            selection: handleSelection
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: { dismiss() })
            }
        }
    }
    
    func handleSelection(_ template: Template) {
        print("not implemented")
    }
    
    #if os(macOS)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    private let heightDivisor: CGFloat = 3
    #else
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    private let heightDivisor: CGFloat = 3
    #endif
}

struct TemplateTile: View {
    @Environment(\.colorScheme) var colorScheme
    
    typealias Callback = (Template) -> Void
    
    let template: Template
    let height: CGFloat
    let selection: Callback
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let picture = template.picture {
                PictureView(asset: picture)
                    .frame(height: height)
                    .clipShape(.rect(cornerRadius: 8, style: .continuous))
            }
            VStack(alignment: .leading) {
                Text(template.title)
                    .font(.system(size: 13, weight: .medium))
                if let subtitle = template.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .onTapGesture {
            selection(template)
        }
    }
}

#Preview {
    NavigationStack {
        TemplateListView()
    }.environment(Store.preview)
}
