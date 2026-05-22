import Foundation

enum WelcomeStorage {
    private static let key = "netic.hasCompletedWelcome"

    static var hasCompletedWelcome: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markWelcomeCompleted() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
