import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let accent = Color(red: 0.2, green: 0.75, blue: 0.45)
    static let cardBg = Color(red: 0.08, green: 0.08, blue: 0.08)
}

struct FullScreenOverlay<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            AppTheme.background
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
}
