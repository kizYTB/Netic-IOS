import Foundation

class AppVersionManager {
    static let shared = AppVersionManager()
    
    private let versionURL = URL(string: "https://neticai.fr/mobile/version.xml")!
    
    func checkForUpdates(completion: @escaping (Bool, String?) -> Void) {
        URLSession.shared.dataTask(with: versionURL) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, nil)
                return
            }
            
            // Simple XML parsing for <version>X.Y.Z</version>
            let content = String(data: data, encoding: .utf8) ?? ""
            if let range = content.range(of: "<version>"),
               let endRange = content.range(of: "</version>", range: range.upperBound..<content.endIndex) {
                let latestVersion = String(content[range.upperBound..<endRange.lowerBound])
                
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                
                let hasUpdate = latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending
                completion(hasUpdate, latestVersion)
            } else {
                completion(false, nil)
            }
        }.resume()
    }
}
