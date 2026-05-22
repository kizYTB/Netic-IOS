import SwiftUI

struct ContentView: View {
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var webViewState = WebViewState()
    private let url = URL(string: "https://neticai.fr/chat")!
    
    // Identifiant pour forcer la recréation de la WebView lors d'un retry
    @State private var webViewId = UUID()

    var body: some View {
        ZStack {
            // Fond de l'application
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            // WebView principale
            if networkMonitor.isConnected && !webViewState.hasError {
                WebView(url: url, webViewState: webViewState)
                    .id(webViewId)
                    .ignoresSafeArea(.all, edges: .bottom)
            }

            // Écran de chargement
            if webViewState.isLoading && networkMonitor.isConnected && !webViewState.hasError {
                LoadingView()
                    .transition(.opacity)
            }

            // Écran d'erreur ou hors-ligne
            if !networkMonitor.isConnected || webViewState.hasError {
                OfflineView(
                    isNetworkError: !networkMonitor.isConnected,
                    retryAction: {
                        withAnimation {
                            webViewState.hasError = false
                            webViewState.isLoading = true
                            webViewId = UUID() // Force la WebView à se recharger
                        }
                    }
                )
            }
        }
        .animation(.easeInOut, value: webViewState.isLoading)
        .animation(.easeInOut, value: webViewState.hasError)
        .animation(.easeInOut, value: networkMonitor.isConnected)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            VStack(spacing: 30) {
                // Logo de l'application au centre
                if let appIcon = UIImage(named: "AppIcon") {
                    Image(uiImage: appIcon)
                        .resizable()
                        .frame(width: 120, height: 120)
                        .cornerRadius(26)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                } else {
                    // Fallback si l'image ne charge pas dans le preview
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color.blue)
                        .frame(width: 120, height: 120)
                        .overlay(Text("N").font(.largeTitle).foregroundColor(.white))
                }
                
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Connexion à Netic AI...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct OfflineView: View {
    var isNetworkError: Bool
    var retryAction: () -> Void

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: isNetworkError ? "wifi.slash" : "server.rack")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text(isNetworkError ? "Aucune connexion" : "Serveur inaccessible")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(isNetworkError ? "Vérifiez votre connexion internet et réessayez." : "Les serveurs de Netic AI sont actuellement injoignables. Veuillez réessayer plus tard.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundColor(.secondary)
                
                Button(action: retryAction) {
                    Text("Réessayer")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                }
                .padding(.top, 10)
            }
        }
    }
}

#Preview {
    ContentView()
}
