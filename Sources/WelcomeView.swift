import SwiftUI

// MARK: - Séquence d'intro (~5 s)

private enum WelcomeSequence: Int, Comparable {
    case boot = 0       // 0.0 – 0.9 s  logo + particules
    case installing = 1 // 0.9 – 2.8 s  anneau de progression
    case success = 2    // 2.8 – 3.8 s  validation + onde
    case reveal = 3     // 3.8 – 4.6 s  textes
    case ready = 4      // 4.6 – 5.0 s+ bouton

    static func < (lhs: WelcomeSequence, rhs: WelcomeSequence) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct WelcomeView: View {
    var onContinue: () -> Void

    @State private var sequence: WelcomeSequence = .boot
    @State private var installProgress: CGFloat = 0
    @State private var logoScale: CGFloat = 0.2
    @State private var logoOpacity: Double = 0
    @State private var logoBlur: CGFloat = 16
    @State private var checkScale: CGFloat = 0
    @State private var checkOpacity: Double = 0
    @State private var burstScale: CGFloat = 0.5
    @State private var burstOpacity: Double = 0
    @State private var titleOffset: CGFloat = 28
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var bodyOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 24
    @State private var shimmerOffset: CGFloat = -1.2
    @State private var canContinue = false
    @State private var statusText = "Préparation…"
    @State private var loadingDots = ""

    var body: some View {
        FullScreenOverlay {
            ZStack {
                FloatingParticlesView()
                    .opacity(sequence >= .boot ? 1 : 0)

                VStack(spacing: 0) {
                    Spacer()

                    heroSection
                        .padding(.bottom, 36)

                    textSection
                        .padding(.horizontal, 28)

                    Spacer()

                    footerSection
                        .padding(.horizontal, 28)
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            startCinematicSequence()
            startDotsAnimation()
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        ZStack {
            // Onde de succès
            Circle()
                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 2)
                .frame(width: 200, height: 200)
                .scaleEffect(burstScale)
                .opacity(burstOpacity)

            Circle()
                .stroke(AppTheme.accent.opacity(0.25), lineWidth: 1)
                .frame(width: 240, height: 240)
                .scaleEffect(burstScale * 1.15)
                .opacity(burstOpacity * 0.6)

            // Anneau de progression (phase installation)
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 6)
                .frame(width: 132, height: 132)

            Circle()
                .trim(from: 0, to: installProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            AppTheme.accent,
                            Color.blue.opacity(0.8),
                            AppTheme.accent
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(-90))
                .opacity(sequence >= .installing && sequence < .success ? 1 : 0)
                .animation(.easeInOut(duration: 1.6), value: installProgress)

            // Halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.35), Color.clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .opacity(logoOpacity * 0.9)

            ZStack {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 30)
                    .overlay(shimmerOverlay.mask(
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    ))

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white, AppTheme.accent)
                    .offset(x: 48, y: 48)
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .blur(radius: logoBlur)

            VStack(spacing: 6) {
                Text(statusText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Text(loadingDots)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 24)
            }
            .offset(y: 118)
            .opacity(sequence <= .installing ? 1 : 0)
        }
    }

    private var shimmerOverlay: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.45),
                Color.clear
            ],
            startPoint: UnitPoint(x: shimmerOffset, y: 0),
            endPoint: UnitPoint(x: shimmerOffset + 0.35, y: 1)
        )
    }

    private var textSection: some View {
        VStack(spacing: 14) {
            Text("Bienvenue sur Netic AI")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(titleOpacity)
                .offset(y: titleOffset)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(AppTheme.accent)
                Text("Installation réussie")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.accent.opacity(0.15))
            .clipShape(Capsule())
            .opacity(subtitleOpacity)
            .scaleEffect(subtitleOpacity == 0 ? 0.85 : 1)

            Text("Votre assistant IA est prêt. Discutez, analysez des images et dictez vos messages — directement depuis votre iPhone.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .opacity(bodyOpacity)
                .offset(y: bodyOpacity == 0 ? 12 : 0)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 16) {
            ProgressView(value: min(sequence == .ready ? 1 : Double(sequence.rawValue) / 4.0, 1.0), total: 1.0)
                .tint(AppTheme.accent)
                .opacity(sequence >= .reveal ? 0.5 : 0)

            Button(action: finishWelcome) {
                Text(canContinue ? "C'est parti !" : "Un instant…")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(canContinue ? .black : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canContinue ? Color.white : Color.white.opacity(0.12))
                    .clipShape(Capsule())
                    .shadow(color: canContinue ? Color.white.opacity(0.2) : .clear, radius: 16, y: 4)
            }
            .disabled(!canContinue)
            .opacity(buttonOpacity)
            .offset(y: buttonOffset)
            .scaleEffect(canContinue ? 1 : 0.98)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: canContinue)
        }
    }

    // MARK: - Animation (~5 s)

    private func startCinematicSequence() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        // Phase 1 — Boot (0.9 s)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.68)) {
            logoScale = 1
            logoOpacity = 1
            logoBlur = 0
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)

            // Phase 2 — Installation (1.9 s)
            sequence = .installing
            statusText = "Installation"
            withAnimation(.easeInOut(duration: 1.7)) {
                installProgress = 1
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            try? await Task.sleep(nanoseconds: 1_900_000_000)

            // Phase 3 — Succès (1.0 s)
            sequence = .success
            statusText = "Terminé"
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                checkScale = 1.15
                checkOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.85)) {
                burstScale = 1.35
                burstOpacity = 1
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                checkScale = 1
            }

            try? await Task.sleep(nanoseconds: 650_000_000)

            // Phase 4 — Textes (0.8 s)
            sequence = .reveal
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                titleOpacity = 1
                titleOffset = 0
            }

            try? await Task.sleep(nanoseconds: 280_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                subtitleOpacity = 1
            }

            try? await Task.sleep(nanoseconds: 320_000_000)
            withAnimation(.easeOut(duration: 0.5)) {
                bodyOpacity = 1
            }

            try? await Task.sleep(nanoseconds: 200_000_000)

            // Phase 5 — Bouton (0.4 s + fin)
            sequence = .ready
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                buttonOpacity = 1
                buttonOffset = 0
            }

            try? await Task.sleep(nanoseconds: 400_000_000)
            canContinue = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            // Shimmer continu sur le logo
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                shimmerOffset = 1.8
            }
        }
    }

    private func startDotsAnimation() {
        Task { @MainActor in
            let frames = ["", ".", "..", "..."]
            var index = 0
            while !canContinue {
                loadingDots = frames[index % frames.count]
                index += 1
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
            loadingDots = ""
        }
    }

    private func finishWelcome() {
        guard canContinue else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.4)) {
            onContinue()
        }
    }
}

// MARK: - Particules d'ambiance

private struct FloatingParticlesView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for index in 0..<18 {
                    let seed = Double(index) * 1.7
                    let x = (sin(t * 0.35 + seed) * 0.5 + 0.5) * size.width
                    let y = (cos(t * 0.28 + seed * 1.3) * 0.5 + 0.5) * size.height
                    let radius = 2 + CGFloat(index % 4)
                    let alpha = 0.08 + (sin(t + seed) + 1) * 0.06
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(index % 3 == 0 ? AppTheme.accent.opacity(alpha) : Color.white.opacity(alpha * 0.7))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
