import SwiftUI

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

#Preview {
    LoadingView()
}
