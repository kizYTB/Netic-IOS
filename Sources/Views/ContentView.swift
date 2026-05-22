import SwiftUI

struct ContentView: View {
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var webViewState = WebViewState()
    private let url = URL(string: "https://neticai.fr/chat")!

    @State private var webViewId = UUID()
    @State private var showWelcome = !WelcomeStorage.hasCompletedWelcome

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea(.all)

            WebView(url: url, webViewState: webViewState)
                .id(webViewId)
                .opacity(networkMonitor.isConnected ? 1 : 0)

            if webViewState.isLoading && networkMonitor.isConnected {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(5)
            }

            if !networkMonitor.isConnected {
                OfflineView(retryAction: { webViewId = UUID() })
                    .zIndex(6)
            }

            if showWelcome {
                WelcomeView {
                    WelcomeStorage.markWelcomeCompleted()
                    showWelcome = false
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .animation(.easeInOut(duration: 0.5), value: webViewState.isLoading)
        .animation(.easeInOut(duration: 0.5), value: networkMonitor.isConnected)
        .animation(.easeInOut(duration: 0.8), value: showWelcome)
    }
}

#Preview {
    ContentView()
}
