import SwiftUI

struct ContentView: View {
    @StateObject private var state = WebViewState()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    // The main URL of the Netic application
    // Corrected: Using neticai.fr as the main production domain
    private let appURL = URL(string: "https://neticai.fr")!

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
            if state.isLoading && networkMonitor.isConnected {
                LoadingView()
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
