import SwiftUI

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
                        .background(Capsule().fill(Color.white))
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    OfflineView(retryAction: {})
}
