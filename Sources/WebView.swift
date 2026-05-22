import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var webViewState: WebViewState
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        userContentController.add(context.coordinator, name: "netic")
        config.userContentController = userContentController
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        
        let defaultUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        webView.customUserAgent = "\(defaultUserAgent) netic-ios"
        
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.webViewState.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.webViewState.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }
        
        private func handleError(_ error: Error) {
            let nsError = error as NSError
            print("WebView Error: \(nsError.localizedDescription) (Code: \(nsError.code))")
            
            // Toujours arrêter le chargement sans bloquer l'UI
            DispatchQueue.main.async {
                self.parent.webViewState.isLoading = false
            }
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "netic" else { return }
            
            if let body = message.body as? [String: Any],
               let type = body["type"] as? String {
                switch type {
                case "vibrate":
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                default:
                    break
                }
            }
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                print("Demande d'ouverture de fenêtre: \(url.absoluteString)")
                // Si c'est une redirection d'authentification ou un lien externe
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        // Gérer les redirections OAuth
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            print("Navigation vers: \(url.absoluteString)")
            
            // Si on navigue sur jtheberg mais qu'on n'est plus dans le flux d'authentification (ex: espace client)
            if url.absoluteString.contains("jtheberg.cloud") || url.absoluteString.contains("jtheberg") {
                if !url.absoluteString.contains("oauth") && !url.absoluteString.contains("authorize") && !url.absoluteString.contains("login") {
                    print("Redirection hors de l'auth Jtheberg -> Retour au chat Netic")
                    if let chatUrl = URL(string: "https://neticai.fr/chat") {
                        webView.load(URLRequest(url: chatUrl))
                        decisionHandler(.cancel)
                        return
                    }
                }
            }
            
            // Si l'URL tente d'ouvrir une application externe (comme l'app Jtheberg ou un lien profond)
            if !url.absoluteString.hasPrefix("http://") && !url.absoluteString.hasPrefix("https://") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                } else {
                    // Si on ne peut pas l'ouvrir, on laisse couler mais on ne veut pas déclencher d'erreur bloquante
                    decisionHandler(.allow)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
        
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
    }
}
