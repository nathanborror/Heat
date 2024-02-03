import SwiftUI

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

func ??(lhs: Binding<Optional<URL>>, rhs: URL) -> Binding<String> {
    Binding(
        get: { lhs.wrappedValue?.absoluteString ?? rhs.absoluteString },
        set: { lhs.wrappedValue = URL(string: $0) }
    )
}
