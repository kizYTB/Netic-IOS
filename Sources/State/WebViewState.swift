import Foundation

class WebViewState: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
}
