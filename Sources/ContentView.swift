import SwiftUI

struct ContentView: View {
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var webViewState = WebViewState()
    private let url = URL(string: "https://neticai.fr/chat")!
    
    @State private var webViewId = UUID()

    var body: some View {
        ZStack {
            // Fond noir profond (Ultra clean)
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
            
            // WebView principale : Toujours en arrière-plan, jamais détruite
            // L'opacité est à 0 seulement si pas de réseau, pour cacher la page cassée
            WebView(url: url, webViewState: webViewState)
                .id(webViewId)
                .ignoresSafeArea(.all, edges: .bottom)
                .opacity(networkMonitor.isConnected ? 1 : 0)

            // Écran de chargement ultra minimaliste
            if webViewState.isLoading && networkMonitor.isConnected {
                LoadingView()
                    .transition(.opacity)
            }

            // Écran hors-ligne (Masque tout le reste)
            if !networkMonitor.isConnected {
                OfflineView(
                    retryAction: {
                        webViewId = UUID()
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.4), value: webViewState.isLoading)
        .animation(.easeInOut(duration: 0.4), value: networkMonitor.isConnected)
    }
}

struct LoadingView: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.white.opacity(0.1), radius: 20, x: 0, y: 0)
                    .scaleEffect(isPulsing ? 1.02 : 0.98)
                    .opacity(isPulsing ? 1 : 0.7)
                    .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}

struct OfflineView: View {
    var retryAction: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
            
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
                    .padding(.horizontal, 40)
                
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
        }
    }
}

#Preview {
    ContentView()
}
