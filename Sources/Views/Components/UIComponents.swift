import SwiftUI
import UIKit

struct LoadingView: View {
    var body: some View {
        FullScreenOverlay {
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Text("Chargement...")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
        }
    }
}

struct OfflineView: View {
    var retryAction: () -> Void
    var body: some View {
        FullScreenOverlay {
            VStack(spacing: 24) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.white.opacity(0.4))
                VStack(spacing: 8) {
                    Text("Pas de connexion")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Vérifiez votre accès internet pour utiliser Netic.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                Button(action: retryAction) {
                    Text("Réessayer")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.white))
                }
            }
            .padding(40)
        }
    }
}
