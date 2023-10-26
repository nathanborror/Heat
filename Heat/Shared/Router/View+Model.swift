import SwiftUI

extension View {
    
    func modal<Item, Content>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, content: @escaping (Item) -> Content) -> some View where Item: Identifiable, Content: View {
        ZStack(alignment: .center) {
            self
            if let wrappedItem = item.wrappedValue {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            item.wrappedValue = nil
                        } label: {
                            Image(systemName: "xmark.circle")
                        }
                        
                        Spacer()
                    }.frame(height: 50)
                    .padding(.horizontal, 12)
                    
                    Divider()
                    content(wrappedItem)
                }.clipShape(RoundedRectangle(cornerRadius: 8))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(.white)
                ).padding(.horizontal, 16)
            }
        }
    }
}
