import SwiftUI
import WebKit
import PDFKit
import SharedKit
import HeatKit

#if os(macOS)
public struct ArtifactView: NSViewRepresentable {
    public typealias NSViewType = WKWebView
    
    var viewModel: ArtifactViewModel
    var view = WKWebView()
    
    public func makeNSView(context: Context) -> NSViewType {
        view.navigationDelegate = context.coordinator
        return view
    }
    
    public func updateNSView(_ view: NSViewType, context: Context) {
        if let url = viewModel.artifact.url {
            var request = URLRequest(url: url)
            request.httpShouldHandleCookies = false
            request.setValue(viewModel.userAgent.rawValue, forHTTPHeaderField: "User-Agent")
            view.load(request)
        }
    }
    
    public func makeCoordinator() -> ArtifactViewCoordinator {
        ArtifactViewCoordinator(self, viewModel)
    }
}
#else
public struct ArtifactView: UIViewRepresentable {
    public typealias UIViewType = WKWebView
    
    var viewModel: ArtifactViewModel
    var view = WKWebView()
    
    public func makeUIView(context: Context) -> UIViewType {
        view.navigationDelegate = context.coordinator
        return view
    }
    
    public func updateUIView(_ view: UIViewType, context: Context) {
        if let url = viewModel.artifact.url {
            var request = URLRequest(url: url)
            request.httpShouldHandleCookies = false
            request.setValue(viewModel.userAgent.rawValue, forHTTPHeaderField: "User-Agent")
            view.load(request)
        }
    }
    
    public func makeCoordinator() -> ArtifactViewCoordinator {
        ArtifactViewCoordinator(self, viewModel)
    }
}
#endif

@Observable
class ArtifactViewModel {
    typealias CompletionHandler = (String) -> Void
    
    var artifact: Artifact
    var kind: ResponseKind
    var userAgent: UserAgent
    var completion: CompletionHandler
    
    enum ResponseKind {
        case source
        case plaintext
    }
    
    enum UserAgent: String {
        case desktop = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
        case mobile = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1"
    }
    
    init(artifact: Artifact, kind: ResponseKind, userAgent: UserAgent, completion: @escaping CompletionHandler) {
        self.artifact = artifact
        self.kind = kind
        self.userAgent = userAgent
        self.completion = completion
    }
}

public class ArtifactViewCoordinator: NSObject, WKNavigationDelegate {
    var parent: ArtifactView
    var parentViewModel: ArtifactViewModel
    
    init(_ parent: ArtifactView, _ parentViewModel: ArtifactViewModel) {
        self.parent = parent
        self.parentViewModel = parentViewModel
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task {
            switch parentViewModel.kind {
            case .source:
                let output = try await viewSource()
                parentViewModel.completion(output)
            case .plaintext:
                let output = try await viewPlaintext()
                parentViewModel.completion(output)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        print("WebView Error (didFail):", error)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        print("WebView Error (didFailProvisionalNavigation):", error)
    }
    
    private func viewSource() async throws -> String {
        let source = try await parent.view.evaluateJavaScript("document.body.innerHTML.toString()")
        return source as? String ?? ""
    }
    
    private func viewPlaintext() async throws -> String {
        let data = try await parent.view.pdf()
        return PDFDocument(data: data)?.string ?? ""
    }
}
