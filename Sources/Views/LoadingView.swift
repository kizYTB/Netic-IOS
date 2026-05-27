import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Animated Logo
                ZStack {
                    Circle()
                        .fill(Color(red: 0.05, green: 0.65, blue: 0.91).opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.2 : 0.9)
                        .blur(radius: isAnimating ? 20 : 10)
                    
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Netic AI")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Initialisation de votre assistant...")
                        .font(.system(size: 14))
                        .foregroundColor(.zinc400)
                }
            }
        }
    }
}

// Extension to use Zinc colors if needed (Netic style)
extension Color {
    static let zinc400 = Color(red: 0.63, green: 0.63, blue: 0.65)
    static let neticPrimary = Color(red: 0.05, green: 0.65, blue: 0.91)
}
