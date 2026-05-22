import Foundation

class WebViewState: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var hasError: Bool = false
    @Published var errorDescription: String? = nil
}
