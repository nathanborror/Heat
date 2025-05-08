import SwiftUI

#if os(macOS)
typealias PlatformViewControllerRepresentable = NSViewControllerRepresentable
#else
typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
#endif

struct MagicEditor: PlatformViewControllerRepresentable {
    @Binding var viewModel: MagicEditorManager

    func makeViewController(context: Context) -> MagicEditorViewController {
        let controller = MagicEditorViewController()
        viewModel.connect(to: controller)
        return controller
    }

    func updateViewController(_ controller: MagicEditorViewController, context: Context) {
    }

    #if os(macOS)
    func makeNSViewController(context: Context) -> MagicEditorViewController {
        makeViewController(context: context)
    }
    func updateNSViewController(_ controller: MagicEditorViewController, context: Context) {
        updateViewController(controller, context: context)
    }
    #else
    func makeUIViewController(context: Context) -> MagicEditorViewController {
        makeViewController(context: context)
    }
    func updateUIViewController(_ controller: MagicEditorViewController, context: Context) {
        updateViewController(controller, context: context)
    }
    #endif
}
