import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    @State private var isVisible = false
    @State private var isFadingOut = false

    var body: some View {
        FullScreenOverlay {
            ZStack {
                // Fond noir pour le "fondue au noir"
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 20)

                    VStack(spacing: 16) {
                        Text("Netic AI")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Votre assistant IA personnel")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button(action: finishWelcome) {
                        Text("C'est parti !")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Capsule().fill(Color.white))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
            }
            .opacity(isFadingOut ? 0 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
        }
    }

    private func finishWelcome() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeInOut(duration: 0.6)) {
            isFadingOut = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onContinue()
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
