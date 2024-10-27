import SwiftUI

#if os(macOS)
class FloatingPanel<Content: View>: NSPanel {
    @Binding var isPresented: Bool

    init(view: () -> Content, contentRect: CGRect, backing: NSWindow.BackingStoreType = .buffered, defer flag: Bool = false, isPresented: Binding<Bool>) {
        self._isPresented = isPresented

        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .resizable, .closable, .fullSizeContentView],
            backing: backing,
            defer: flag
        )

        // Allow panel to be on top of other windows
        isFloatingPanel = true
        level = .floating

        // Allow panel to overlay a fullscreen space
        collectionBehavior.insert(.fullScreenAuxiliary)

        // Make panel movable by dragging background
        isMovableByWindowBackground = true

        // Hide when unfocused
        hidesOnDeactivate = true

        // Hides title bar and allows the panel to be resizable
        styleMask = .nonactivatingPanel
        styleMask.insert(.resizable)

        // Set animations accordingly
        animationBehavior = .utilityWindow

        // Hide background color and control corner radius on hosting view
        backgroundColor = .clear

        // Set content view, ignore safe area so there's no interference with the title bar
        contentView = NSHostingView(rootView: view().environment(\.floatingPanel, self))
    }

    override func resignMain() {
        super.resignMain()
        close()
    }

    override func close() {
        super.close()
        isPresented = false
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - Environment

private struct FloatingPanelKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}

extension EnvironmentValues {
    var floatingPanel: NSPanel? {
        get { self[FloatingPanelKey.self] }
        set { self[FloatingPanelKey.self] = newValue }
    }
}

// MARK: - View Modifier

struct FloatingPanelModifier<PanelContent: View>: ViewModifier {

    /// Determines whether the panel should be presented or not.
    @Binding var isPresented: Bool

    /// Panel starting size.
    var contentRect = CGRect(x: 0, y: 0, width: 512, height: 256)

    /// Panel view contents.
    @ViewBuilder let view: () -> PanelContent

    /// Panel instance with same generic type as the view closure.
    @State var panel: FloatingPanel<PanelContent>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                panel = FloatingPanel(view: view, contentRect: contentRect, isPresented: $isPresented)
                panel?.center()
                if isPresented {
                    present()
                }
            }
            .onDisappear {
                panel?.close()
                panel = nil
            }
            .onChange(of: isPresented) { _, newValue in
                newValue ? present() : panel?.close()
            }
    }

    func present() {
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension View {

    /// Present a ``FloatingPanel`` in SwiftUI fashion.
    /// - Parameter isPresented: A boolean binding that keeps track of the panel's presentation state.
    /// - Parameter contentRect: The initial content frame of the window.
    /// - Parameter content: The displayed content.
    func floatingPanel<Content: View>(isPresented: Binding<Bool>,
                                      contentRect: CGRect = .init(x: 0, y: 0, width: 512, height: 256),
                                      @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(FloatingPanelModifier(isPresented: isPresented, contentRect: contentRect, view: content))
    }
}
#endif
