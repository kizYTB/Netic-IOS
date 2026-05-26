import SwiftUI
import WebKit

struct WebView: UIViewControllerRepresentable {
    let url: URL
    @ObservedObject var webViewState: WebViewState

    func makeUIViewController(context: Context) -> WebViewController {
        WebViewController(url: url, webViewState: webViewState)
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {}
}

final class WebViewController: UIViewController {
    private let url: URL
    private let webViewState: WebViewState
    private var webView: WKWebView!

    init(url: URL, webViewState: WebViewState) {
        self.url = url
        self.webViewState = webViewState
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        setupWebView()
        setupConstraints()
        webView.load(URLRequest(url: url))
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(viewportScript)
        config.userContentController = userContentController
        
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default()

        // Initialisation immédiate avec la taille de l'écran pour éviter le letterboxing
        webView = WKWebView(frame: UIScreen.main.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self
        
        // User Agent moderne
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 NeticApp/1.1"

        let bg = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        webView.isOpaque = true
        webView.backgroundColor = bg
        webView.scrollView.backgroundColor = bg
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = true
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Force la WebView à ne pas redimensionner sa fenêtre lors de l'apparition du clavier
        // Cela permet de garder le layout du site web stable
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            self.webView.setNeedsLayout()
        }
    }

    private var viewportScript: WKUserScript {
        let js = """
        (function() {
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
                meta = document.createElement('meta');
                meta.setAttribute('name', 'viewport');
                (document.head || document.documentElement).appendChild(meta);
            }
            meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, viewport-fit=cover');
            
            // Fix radical pour la résolution et le plein écran
            // On utilise position: fixed pour que le site ne bouge pas du tout
            document.documentElement.style.position = 'fixed';
            document.documentElement.style.top = '0';
            document.documentElement.style.left = '0';
            document.documentElement.style.right = '0';
            document.documentElement.style.bottom = '0';
            document.documentElement.style.height = '100%';
            document.documentElement.style.width = '100%';
            document.documentElement.style.overflow = 'hidden';
            
            document.body.style.position = 'fixed';
            document.body.style.top = '0';
            document.body.style.left = '0';
            document.body.style.right = '0';
            document.body.style.bottom = '0';
            document.body.style.margin = '0';
            document.body.style.padding = '0';
            document.body.style.height = '100%';
            document.body.style.width = '100%';
            
            document.documentElement.style.webkitTapHighlightColor = 'transparent';
            
            // On désactive le décalage automatique du clavier sur le web
            window.addEventListener('resize', function() {
                if (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'TEXTAREA') {
                    window.scrollTo(0, 0);
                    document.body.scrollTop = 0;
                }
            });
        })();
        """
        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}

extension WebViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { nil }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        webViewState.isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewState.isLoading = false
        webViewState.canGoBack = webView.canGoBack
        webViewState.canGoForward = webView.canGoForward
        webView.evaluateJavaScript("document.documentElement.style.backgroundColor = '#0d0d0d'; document.body.style.backgroundColor = '#0d0d0d';")
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, !url.absoluteString.hasPrefix("http") {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.request.url != nil { webView.load(navigationAction.request) }
        return nil
    }
}
