import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    @State private var showLogo = false
    @State private var showRing = false
    @State private var showCheck = false
    @State private var showTexts = false
    @State private var showButton = false
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0

    private let background = Color(red: 0.05, green: 0.05, blue: 0.05)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            // Halo animé derrière le logo
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                .frame(width: 160, height: 160)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(showLogo ? 1 : 0.5)
                .opacity(showLogo ? 1 : 0)

            VStack(spacing: 28) {
                ZStack {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .shadow(color: .white.opacity(0.15), radius: 24)
                        .scaleEffect(showLogo ? 1 : 0.3)
                        .opacity(showLogo ? 1 : 0)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white, Color(red: 0.2, green: 0.75, blue: 0.45))
                        .offset(x: 44, y: 44)
                        .scaleEffect(showCheck ? 1 : 0.01)
                        .opacity(showCheck ? 1 : 0)
                }
                .padding(.bottom, 8)

                VStack(spacing: 12) {
                    Text("Bienvenue sur Netic AI")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("L'application est installée avec succès.")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.75, blue: 0.45))

                    Text("Discutez avec votre assistant, analysez des images et utilisez la transcription vocale — tout depuis votre iPhone.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .opacity(showTexts ? 1 : 0)
                .offset(y: showTexts ? 0 : 16)

                Button(action: finishWelcome) {
                    Text("C'est parti !")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 12)
            }
            .padding(.top, 40)
        }
        .onAppear(perform: runIntroAnimation)
    }

    private func runIntroAnimation() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            showLogo = true
        }

        withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
            ringScale = 1.15
            ringOpacity = 1
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.65).delay(0.45)) {
            showCheck = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.65)) {
            showTexts = true
        }

        withAnimation(.easeOut(duration: 0.45).delay(0.95)) {
            showButton = true
        }
    }

    private func finishWelcome() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.easeInOut(duration: 0.35)) {
            onContinue()
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
