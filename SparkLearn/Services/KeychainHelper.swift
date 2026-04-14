import Foundation
import Security

/// Secure storage using iOS Keychain
final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func save(_ data: Data, for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.sparklearn.app"
        ]
        // Delete existing
        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data
        SecItemAdd(newQuery as CFDictionary, nil)
    }

    func read(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.sparklearn.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.sparklearn.app"
        ]
        SecItemDelete(query as CFDictionary)
    }

    // Convenience: save/read Codable
    func save<T: Encodable>(_ value: T, for key: String) {
        if let data = try? JSONEncoder().encode(value) {
            save(data, for: key)
        }
    }

    func read<T: Decodable>(_ type: T.Type, for key: String) -> T? {
        guard let data = read(for: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
