import SwiftUI

@main
struct NeticApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .ignoresSafeArea(.all)
        }
    }
}
