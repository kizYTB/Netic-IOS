import SwiftUI
import WebKit
import UIKit

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
    private var webViewBottomConstraint: NSLayoutConstraint!

    init(url: URL, webViewState: WebViewState) {
        self.url = url
        self.webViewState = webViewState
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        // CORRECTIF BARRES NOIRES : étendre le layout sous toutes les barres
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)

        setupWebView()
        setupConstraints()
        setupKeyboardObservers()
        webView.load(URLRequest(url: url))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.addUserScript(viewportScript)
        config.userContentController = userContentController
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self

        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 NeticApp/1.1"

        let bg = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        webView.isOpaque = true
        webView.backgroundColor = bg
        webView.scrollView.backgroundColor = bg

        // CORRECTIF CLAVIER : on garde "always" pour que iOS gère le clavier proprement
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.scrollView.bounces = true

        if #available(iOS 16.4, *) { webView.isInspectable = true }
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        view.addSubview(webView)

        // Ancres top/leading/trailing sur view (pas safeArea) → plein écran
        webViewBottomConstraint = webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webViewBottomConstraint
        ])
    }

    // CORRECTIF CLAVIER : remonter la webview quand le clavier apparaît
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let keyboardHeight = keyboardFrame.height
        UIView.animate(withDuration: duration) {
            self.webViewBottomConstraint.constant = -keyboardHeight
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: duration) {
            self.webViewBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
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
            document.documentElement.style.webkitTapHighlightColor = 'transparent';
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
