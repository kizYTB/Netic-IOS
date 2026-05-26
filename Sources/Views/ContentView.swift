import SwiftUI

struct ContentView: View {
    @StateObject private var network = NetworkMonitor()
    @StateObject private var webState = WebViewState()
    @State private var webViewId = UUID()

    private let url = URL(string: "https://neticai.fr/chat")!

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea(.all)

            WebView(url: url, webViewState: webState)
                .id(webViewId)
                .ignoresSafeArea(.all) // barres + clavier gérés dans UIKit directement

            if webState.isLoading && network.isConnected {
                LoadingView()
            }

            if !network.isConnected {
                OfflineView {
                    webViewId = UUID()
                }
            }
        }
        .ignoresSafeArea(.all)
        .preferredColorScheme(.dark)
    }
}
