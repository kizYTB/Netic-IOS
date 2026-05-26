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

            // WebView configurée pour ignorer TOUT (top, bottom, keyboard)
            WebView(url: url, webViewState: webState)
                .id(webViewId)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
                .opacity(network.isConnected ? 1 : 0)

            if webState.isLoading && network.isConnected {
                LoadingView()
            }

            if !network.isConnected {
                OfflineView {
                    webViewId = UUID()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .preferredColorScheme(.dark)
    }
}
