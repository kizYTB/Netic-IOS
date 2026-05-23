import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var webViewState: WebViewState

    private static let debugServerURL = URL(string: "http://192.168.1.44:7777/event")
    private static let debugSessionId = "webview-fullscreen"
    private static let debugRunId = "pre-fix"

    func makeUIView(context: Context) -> WKWebView {
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

        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isOpaque = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.zoomScale = 1.0
        
        // Force la WebView à ignorer sa propre safe area insets
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        if #available(iOS 13.0, *) {
            webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }

        if #available(iOS 15.0, *) {
            webView.underPageBackgroundColor = webView.backgroundColor
        }

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        webView.allowsBackForwardNavigationGestures = true

        // #region debug-point A:make-uiview
        Coordinator.reportDebugEvent(
            hypothesisId: "A",
            location: "WebView.makeUIView",
            message: "[DEBUG] WKWebView created",
            data: [
                "frame": [
                    "width": webView.frame.size.width,
                    "height": webView.frame.size.height
                ],
                "scrollInset": [
                    "top": webView.scrollView.contentInset.top,
                    "bottom": webView.scrollView.contentInset.bottom
                ],
                "adjustedInset": [
                    "top": webView.scrollView.adjustedContentInset.top,
                    "bottom": webView.scrollView.adjustedContentInset.bottom
                ]
            ]
        )
        // #endregion

        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.webView = uiView

        if uiView.url == nil {
            uiView.load(URLRequest(url: url))
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
            meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, viewport-fit=cover');
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
            meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, viewport-fit=cover');
        }
        
        function propagateBackground() {
            var bodyBg = window.getComputedStyle(document.body).backgroundColor;
            if (bodyBg === 'rgba(0, 0, 0, 0)' || bodyBg === 'transparent') {
                var root = document.querySelector('#root, #__next, #app, main, .app-container, div[id^="app"]');
                if (root) {
                    var rootBg = window.getComputedStyle(root).backgroundColor;
                    if (rootBg !== 'rgba(0, 0, 0, 0)' && rootBg !== 'transparent') {
                        document.documentElement.style.backgroundColor = rootBg;
                        document.body.style.backgroundColor = rootBg;
                    }
                }
            }
        }
        
        propagateBackground();
        setTimeout(propagateBackground, 300);
        setTimeout(propagateBackground, 1000);
        
        window.dispatchEvent(new Event('resize'));
    })();
    """

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView
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
            
            // Re-force insets in case navigation changed it
            webView.scrollView.contentInset = .zero
            webView.scrollView.scrollIndicatorInsets = .zero

            // #region debug-point B:did-finish-native-metrics
            Self.reportDebugEvent(
                hypothesisId: "B",
                location: "WebView.didFinish.native",
                message: "[DEBUG] Native webview metrics after navigation",
                data: [
                    "bounds": [
                        "width": webView.bounds.size.width,
                        "height": webView.bounds.size.height
                    ],
                    "safeAreaInsets": [
                        "top": webView.safeAreaInsets.top,
                        "bottom": webView.safeAreaInsets.bottom
                    ],
                    "contentInset": [
                        "top": webView.scrollView.contentInset.top,
                        "bottom": webView.scrollView.contentInset.bottom
                    ],
                    "adjustedContentInset": [
                        "top": webView.scrollView.adjustedContentInset.top,
                        "bottom": webView.scrollView.adjustedContentInset.bottom
                    ],
                    "contentSize": [
                        "width": webView.scrollView.contentSize.width,
                        "height": webView.scrollView.contentSize.height
                    ]
                ]
            )
            // #endregion

            webView.evaluateJavaScript(WebView.layoutFixScript, completionHandler: nil)
            // #region debug-point C:did-finish-js-metrics
            webView.evaluateJavaScript(
                """
                (function() {
                    var rect = document.documentElement.getBoundingClientRect();
                    return {
                        href: location.href,
                        innerWidth: window.innerWidth,
                        innerHeight: window.innerHeight,
                        clientWidth: document.documentElement.clientWidth,
                        clientHeight: document.documentElement.clientHeight,
                        bodyScrollHeight: document.body ? document.body.scrollHeight : null,
                        bodyOffsetHeight: document.body ? document.body.offsetHeight : null,
                        docScrollHeight: document.documentElement.scrollHeight,
                        docOffsetHeight: document.documentElement.offsetHeight,
                        rectHeight: rect.height,
                        visualViewportHeight: window.visualViewport ? window.visualViewport.height : null,
                        visualViewportOffsetTop: window.visualViewport ? window.visualViewport.offsetTop : null,
                        bodyBackground: document.body ? getComputedStyle(document.body).backgroundColor : null,
                        htmlBackground: getComputedStyle(document.documentElement).backgroundColor
                    };
                })();
                """
            ) { result, _ in
                Self.reportDebugEvent(
                    hypothesisId: "C",
                    location: "WebView.didFinish.js",
                    message: "[DEBUG] JS viewport metrics after navigation",
                    data: [
                        "result": result ?? NSNull()
                    ]
                )
            }
            // #endregion

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
            // #region debug-point D:create-webview
            Self.reportDebugEvent(
                hypothesisId: "D",
                location: "WebView.createWebViewWith",
                message: "[DEBUG] Popup navigation requested",
                data: [
                    "targetFrameNil": navigationAction.targetFrame == nil,
                    "url": navigationAction.request.url?.absoluteString ?? ""
                ]
            )
            // #endregion
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

            // #region debug-point E:navigation-url
            Self.reportDebugEvent(
                hypothesisId: "E",
                location: "WebView.decidePolicyFor",
                message: "[DEBUG] Navigation allowed",
                data: [
                    "url": url.absoluteString,
                    "isMainFrame": navigationAction.targetFrame?.isMainFrame ?? false
                ]
            )
            // #endregion
            decisionHandler(.allow)
        }

        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }

        private static func reportDebugEvent(hypothesisId: String, location: String, message: String, data: [String: Any]) {
            guard let url = WebView.debugServerURL else { return }
            guard JSONSerialization.isValidJSONObject(data) else { return }

            let payload: [String: Any] = [
                "sessionId": WebView.debugSessionId,
                "runId": WebView.debugRunId,
                "hypothesisId": hypothesisId,
                "location": location,
                "msg": message,
                "data": data,
                "ts": Int(Date().timeIntervalSince1970 * 1000)
            ]

            guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            URLSession.shared.dataTask(with: request).resume()
        }
    }
}
