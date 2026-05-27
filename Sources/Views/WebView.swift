import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var state: WebViewState
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Setup JS Bridge
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "netic")
        configuration.userContentController = controller
        
        // Autoriser le chargement de fichiers locaux
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        // Performance & Media
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Scroll behavior
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        
        // Custom UserAgent for Netic detection
        // On force netic-ios pour charger l'interface mobile uniquement
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 netic-ios"
        
        // On charge directement l'URL du chat
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                let urlString = url.absoluteString
                
                // Autoriser les domaines d'authentification Jtheberg et les callbacks
                if urlString.contains("jtheberg.cloud") || 
                   urlString.contains("oauth") || 
                   urlString.contains("/api/auth/") {
                    decisionHandler(.allow)
                    return
                }
                
                // Si le site essaie de rediriger vers la page d'accueil (root)
                // on redirige proprement vers le chat
                if urlString == "https://neticai.fr/" || urlString == "https://neticai.fr" {
                    decisionHandler(.cancel)
                    let chatRequest = URLRequest(url: URL(string: "https://neticai.fr/chat")!)
                    webView.load(chatRequest)
                    return
                }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.state.isLoading = true
                self.parent.state.lastError = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.state.isLoading = false
                self.parent.state.canGoBack = webView.canGoBack
                self.parent.state.currentURL = webView.url
            }
            
            // Bridge mobile standard (AndroidBridge pour compatibilité hooks)
            let script = """
            window.AndroidBridge = {
                getAppVersion: function() { return '\(self.parent.state.appVersion)'; },
                checkForUpdates: function() { window.webkit.messageHandlers.netic.postMessage({type: 'checkForUpdates'}); },
                logout: function() { window.webkit.messageHandlers.netic.postMessage({type: 'logout'}); }
            };
            
            // On s'assure que window.electronAPI n'existe pas pour ne pas charger l'interface desktop
            delete window.electronAPI;
            
            window.dispatchEvent(new CustomEvent('netic-mobile-ready'));
            """
            webView.evaluateJavaScript(script)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.state.isLoading = false
                self.parent.state.lastError = error
            }
        }

        // Bridge: Receive messages from JS
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "netic",
                  let dict = message.body as? [String: Any],
                  let type = dict["type"] as? String else { return }
            
            let data = dict["data"] as? [String: Any]
            
            switch type {
            case "vibrate":
                let style = data?["style"] as? String ?? "medium"
                triggerHaptic(style: style)
                
            case "logout":
                clearCookies(webView: message.webView)
                
            case "checkForUpdates":
                AppVersionManager.shared.checkForUpdates { hasUpdate, version in
                    DispatchQueue.main.async {
                        self.parent.state.isUpdateAvailable = hasUpdate
                        if hasUpdate {
                            // Notify web app about update
                            self.webViewExecute(webView: message.webView, script: "window.dispatchEvent(new CustomEvent('netic-update-available', {detail: '\(version ?? "")'}))")
                        }
                    }
                }
                
            default:
                print("Unhandled message type: \(type)")
            }
        }
        
        private func triggerHaptic(style: String) {
            DispatchQueue.main.async {
                let generator: UIImpactFeedbackGenerator
                switch style {
                case "light": generator = UIImpactFeedbackGenerator(style: .light)
                case "heavy": generator = UIImpactFeedbackGenerator(style: .heavy)
                default: generator = UIImpactFeedbackGenerator(style: .medium)
                }
                generator.impactOccurred()
            }
        }
        
        private func clearCookies(webView: WKWebView?) {
            let dataStore = WKWebsiteDataStore.default()
            let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            let dateFrom = Date(timeIntervalSince1970: 0)
            
            DispatchQueue.main.async {
                dataStore.removeData(ofTypes: dataTypes, modifiedSince: dateFrom) {
                    print("Full site data cleared (cookies, cache, storage)")
                    // On force un rechargement complet
                    let chatURL = URL(string: "https://neticai.fr/chat")!
                    let request = URLRequest(url: chatURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                    webView?.load(request)
                }
            }
        }
        
        private func webViewExecute(webView: WKWebView?, script: String) {
            webView?.evaluateJavaScript(script)
        }
    }
}
