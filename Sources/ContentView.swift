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
                .ignoresSafeArea(.all)
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
        .animation(.easeInOut(duration: 0.4), value: webViewState.isLoading)
        .animation(.easeInOut(duration: 0.4), value: networkMonitor.isConnected)
        .animation(.easeInOut(duration: 0.35), value: showWelcome)
    }
}

struct LoadingView: View {
    @State private var isPulsing = false

    var body: some View {
        FullScreenOverlay {
            VStack(spacing: 40) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.white.opacity(0.1), radius: 20)
                    .scaleEffect(isPulsing ? 1.02 : 0.98)
                    .opacity(isPulsing ? 1 : 0.7)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { isPulsing = true }
    }
}

struct OfflineView: View {
    var retryAction: () -> Void

    var body: some View {
        FullScreenOverlay {
            VStack(spacing: 20) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white.opacity(0.6))

                Text("Aucune connexion")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Netic AI nécessite une connexion internet.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button(action: retryAction) {
                    Text("Réessayer")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
