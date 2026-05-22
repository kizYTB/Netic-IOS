import SwiftUI
import WebKit

/// Conteneur UIKit : force la WKWebView à occuper 100 % de l'écran (fix SwiftUI UIViewRepresentable).
final class WebViewContainer: UIView {
    let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
        backgroundColor = webView.backgroundColor
        clipsToBounds = true

        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resetScrollInsets()
    }

    func resetScrollInsets() {
        let scrollView = webView.scrollView
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
        if #available(iOS 13.0, *) {
            scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        scrollView.contentInsetAdjustmentBehavior = .never
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var webViewState: WebViewState

    func makeUIView(context: Context) -> WebViewContainer {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        userContentController.addUserScript(Self.viewportScript)
        userContentController.add(context.coordinator, name: "netic")
        config.userContentController = userContentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.preferredContentMode = .mobile
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.customUserAgent = Self.mobileUserAgent

        webView.isOpaque = true
        webView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.isOpaque = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.zoomScale = 1.0

        if #available(iOS 15.0, *) {
            webView.underPageBackgroundColor = webView.backgroundColor
        }

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        webView.allowsBackForwardNavigationGestures = true

        let container = WebViewContainer(webView: webView)
        container.resetScrollInsets()

        context.coordinator.container = container
        context.coordinator.webView = webView
        return container
    }

    func updateUIView(_ container: WebViewContainer, context: Context) {
        context.coordinator.container = container
        context.coordinator.webView = container.webView
        container.resetScrollInsets()

        if container.webView.url == nil {
            container.webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private static var viewportScript: WKUserScript {
        let js = """
        (function() {
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
                meta = document.createElement('meta');
                meta.setAttribute('name', 'viewport');
                (document.head || document.documentElement).appendChild(meta);
            }
            meta.setAttribute('content',
                'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, viewport-fit=cover');

            var style = document.getElementById('netic-ios-layout');
            if (!style) {
                style = document.createElement('style');
                style.id = 'netic-ios-layout';
                style.textContent = [
                    'html, body {',
                    '  margin: 0 !important;',
                    '  padding: 0 !important;',
                    '  width: 100% !important;',
                    '  height: 100% !important;',
                    '  min-height: 100dvh !important;',
                    '  overflow-x: hidden !important;',
                    '  -webkit-text-size-adjust: 100%;',
                    '}',
                    ':root {',
                    '  --netic-safe-top: env(safe-area-inset-top);',
                    '  --netic-safe-bottom: env(safe-area-inset-bottom);',
                    '  --netic-safe-left: env(safe-area-inset-left);',
                    '  --netic-safe-right: env(safe-area-inset-right);',
                    '}'
                ].join('\\n');
                (document.head || document.documentElement).appendChild(style);
            }
        })();
        """
        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    private static var mobileUserAgent: String {
        let version = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(version) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 Netic-iOS/1.0"
    }

    private static let layoutFixScript = """
    (function() {
        var meta = document.querySelector('meta[name="viewport"]');
        if (meta) {
            meta.setAttribute('content',
                'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, viewport-fit=cover');
        }
        document.documentElement.style.cssText = 'margin:0;padding:0;width:100%;height:100%;min-height:100dvh;';
        document.body.style.cssText = 'margin:0;padding:0;width:100%;min-height:100dvh;overflow-x:hidden;';
        window.dispatchEvent(new Event('resize'));
    })();
    """

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView
        weak var container: WebViewContainer?
        weak var webView: WKWebView?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.webViewState.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.scrollView.zoomScale = 1.0
            webView.scrollView.minimumZoomScale = 1.0
            webView.scrollView.maximumZoomScale = 1.0
            container?.resetScrollInsets()

            webView.evaluateJavaScript(WebView.layoutFixScript, completionHandler: nil)

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
            DispatchQueue.main.async {
                self.parent.webViewState.isLoading = false
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "netic" else { return }

            if let body = message.body as? [String: Any],
               let type = body["type"] as? String,
               type == "vibrate" {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.request.url != nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if url.absoluteString.contains("jtheberg.cloud") || url.absoluteString.contains("jtheberg") {
                if !url.absoluteString.contains("oauth"),
                   !url.absoluteString.contains("authorize"),
                   !url.absoluteString.contains("login"),
                   let chatUrl = URL(string: "https://neticai.fr/chat") {
                    webView.load(URLRequest(url: chatUrl))
                    decisionHandler(.cancel)
                    return
                }
            }

            if !url.absoluteString.hasPrefix("http://"), !url.absoluteString.hasPrefix("https://") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
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
