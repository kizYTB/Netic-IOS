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

            // WebView configurée pour ignorer TOUT (top, bottom, keyboard)
            WebView(url: url, webViewState: webViewState)
                .id(webViewId)
                .ignoresSafeArea(.all)
                .opacity(networkMonitor.isConnected ? 1 : 0)

            if webViewState.isLoading && networkMonitor.isConnected {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(5)
            }

            if !networkMonitor.isConnected {
                OfflineView(retryAction: { 
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    webViewId = UUID() 
                })
                .zIndex(6)
            }

            if showWelcome {
                WelcomeView {
                    WelcomeStorage.markWelcomeCompleted()
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showWelcome = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
