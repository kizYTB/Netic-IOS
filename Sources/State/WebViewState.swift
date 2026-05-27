import SwiftUI
import Combine

class WebViewState: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var canGoBack: Bool = false
    @Published var currentURL: URL? = nil
    @Published var appVersion: String = "1.0.0"
    @Published var isUpdateAvailable: Bool = false
    @Published var lastError: Error? = nil
    
    init() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.appVersion = version
        }
    }
}
