import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let accent = Color(red: 0.2, green: 0.75, blue: 0.45)
}

/// Overlay qui couvre tout l'écran (y compris notch et barre d'accueil).
struct FullScreenOverlay<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            AppTheme.background
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea(.all)
    }
}
