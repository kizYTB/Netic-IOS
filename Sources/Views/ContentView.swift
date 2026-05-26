import SwiftUI

struct ContentView: View {
    @StateObject private var network = NetworkMonitor()
    @StateObject private var webState = WebViewState()
    @State private var webViewId = UUID()
    
    private let url = URL(string: "https://neticai.fr/chat")!

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea(.all)

            if network.isConnected {
                WebView(url: url, webViewState: webState)
                    .id(webViewId)
                    .ignoresSafeArea(.all)
                    .transition(.opacity)
                
                if webState.isLoading {
                    LoadingView()
                }
            } else {
                OfflineView {
                    webViewId = UUID()
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.default, value: network.isConnected)
        .animation(.default, value: webState.isLoading)
        .preferredColorScheme(.dark)
    }
}
