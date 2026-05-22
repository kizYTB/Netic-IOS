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
        .animation(.easeInOut(duration: 0.3), value: webViewState.isLoading)
        .animation(.easeInOut(duration: 0.3), value: webViewState.hasError)
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }
}

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Fond dégradé subtil
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemBackground),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 35) {
                // Logo avec effet de pulsation
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .cornerRadius(24)
                    .shadow(color: Color.blue.opacity(0.15), radius: 20, x: 0, y: 10)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                    
                    Text("Chargement de votre assistant...")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            isAnimating = true
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
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: isNetworkError ? "wifi.slash" : "exclamationmark.triangle")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.bottom, 10)
                
                Text(isNetworkError ? "Hors Ligne" : "Erreur de connexion")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text(isNetworkError ? "Vérifiez votre connexion internet et réessayez." : "Les serveurs de Netic AI sont actuellement injoignables.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundColor(.secondary)
                
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Réessayer")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 20)
            }
        }
    }
}

#Preview {
    ContentView()
}
