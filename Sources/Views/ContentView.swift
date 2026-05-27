import SwiftUI

struct ContentView: View {
    @StateObject private var state = WebViewState()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    // The main URL of the Netic application
    // Corrected: Loading the chat directly as requested
    private let appURL = URL(string: "https://neticai.fr/chat")!

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if networkMonitor.isConnected {
                WebView(url: appURL, state: state)
                    .edgesIgnoringSafeArea(.all)
            } else {
                OfflineView()
            }
            
            // Splash/Loading Screen
            if state.isLoading && networkMonitor.isConnected && !isAuthPage {
                LoadingView(message: loadingMessage)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Initial check for updates on launch
            AppVersionManager.shared.checkForUpdates { hasUpdate, version in
                DispatchQueue.main.async {
                    self.state.isUpdateAvailable = hasUpdate
                }
            }
        }
    }
    
    private var isAuthPage: Bool {
        guard let url = state.currentURL?.absoluteString.lowercased() else { return false }
        // On considère comme page d'auth tout ce qui touche à Jtheberg, login ou callback
        return url.contains("jtheberg.cloud") || 
               url.contains("login") || 
               url.contains("auth") || 
               url.contains("oauth")
    }
    
    private var loadingMessage: String {
        guard let url = state.currentURL?.absoluteString else {
            return "Initialisation de votre assistant..."
        }
        
        if url.contains("jtheberg.cloud") || url.contains("login") || url.contains("auth") {
            return "Connexion sécurisée..."
        }
        
        return "Chargement de votre assistant..."
    }
}

struct OfflineView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 50))
                .foregroundColor(.zinc400)
            
            Text("Pas de connexion")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Veuillez vérifier votre connexion internet pour continuer à utiliser Netic.")
                .font(.subheadline)
                .foregroundColor(.zinc400)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                // Potential retry logic
            }) {
                Text("Réessayer")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.neticPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
