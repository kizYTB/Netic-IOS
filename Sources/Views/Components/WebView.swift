import SwiftUI
import WebKit

// MARK: - SwiftUI Wrapper

struct WebView: UIViewControllerRepresentable {
    let url: URL
    @ObservedObject var webViewState: WebViewState

    func makeUIViewController(context: Context) -> WebViewController {
        let vc = WebViewController(url: url, webViewState: webViewState)
        return vc
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        // Rien à faire, le VC gère son propre état
    }
}

// MARK: - UIViewController

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

        // Fond identique à AppTheme.background
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)

        setupWebView()
        setupConstraints()

        webView.load(URLRequest(url: url))
    }

    // MARK: - Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(viewportScript)
        userContentController.add(makeCoordinator(), name: "netic")
        config.userContentController = userContentController
        
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default()

        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.preferredContentMode = .mobile
        }

        // Utilise UIScreen.main.bounds pour forcer la taille réelle de l'écran dès le départ
        webView = WKWebView(frame: UIScreen.main.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 NeticApp/1.0"

        let bg = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        webView.isOpaque = true
        webView.backgroundColor = bg
        webView.scrollView.backgroundColor = bg
        webView.scrollView.delegate = self

        if #available(iOS 15.0, *) {
            webView.underPageBackgroundColor = bg
        }

        // IMPORTANT : .never avec viewport-fit=cover permet au site de gérer lui-même ses marges
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Empêche le système de modifier les offsets lors de l'apparition du clavier
        if #available(iOS 13.0, *) {
            webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        view.addSubview(webView)

        // Colle la WebView aux BORDS de la vue (pas à la safe area)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // Réinitialise les insets à chaque changement de safe area (rotation, etc.)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // Ne pas réinitialiser contentInset pour permettre l'ajustement automatique
        webView.scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - Coordinator (message handler)

    private func makeCoordinator() -> MessageHandler {
        MessageHandler()
    }

    // MARK: - Scripts

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
            
            // Empêche le décalage forcé par le système
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
            
            // Fix pour les zones tactiles sur iOS
            document.documentElement.style.webkitTapHighlightColor = 'transparent';
            document.documentElement.style.webkitTouchCallout = 'none';
        })();
        """
        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    private let backgroundFixScript = """
    (function() {
        document.documentElement.style.backgroundColor = '#0d0d0d';
        document.body.style.backgroundColor = '#0d0d0d';
        window.dispatchEvent(new Event('resize'));
    })();
    """
}

// MARK: - WKNavigationDelegate

extension WebViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async { self.webViewState.isLoading = true }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.scrollView.zoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        // Ne pas réinitialiser contentInset pour permettre l'ajustement automatique
        webView.scrollView.scrollIndicatorInsets = .zero
        webView.evaluateJavaScript(backgroundFixScript, completionHandler: nil)
        DispatchQueue.main.async { self.webViewState.isLoading = false }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error)
    }

    private func handleError(_ error: Error) {
        let code = (error as NSError).code
        // Ignore les erreurs de navigation annulée (code -999)
        guard code != -999 else { return }
        print("WebView Error: \(error.localizedDescription)")
        DispatchQueue.main.async { self.webViewState.isLoading = false }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Redirige jtheberg vers neticai.fr/chat (sauf OAuth)
        if url.absoluteString.contains("jtheberg") {
            if !url.absoluteString.contains("oauth"),
               !url.absoluteString.contains("authorize"),
               !url.absoluteString.contains("login"),
               let chatUrl = URL(string: "https://neticai.fr/chat") {
                webView.load(URLRequest(url: chatUrl))
                decisionHandler(.cancel)
                return
            }
        }

        // Ouvre les liens non-http dans l'app système
        if !url.absoluteString.hasPrefix("http://"), !url.absoluteString.hasPrefix("https://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension WebViewController: WKUIDelegate {

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.request.url != nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
}

// MARK: - Message Handler (vibration)

final class MessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "netic",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String,
              type == "vibrate" else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}