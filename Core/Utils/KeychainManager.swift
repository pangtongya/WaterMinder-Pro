import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.pangtong.bloom"

    private init() {}

    // MARK: - Save

    @discardableResult
    func save(_ data: Data, for key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Load

    func load(for key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return data
    }

    // MARK: - Delete

    func delete(for key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Convenience (Bool)

    func saveBool(_ value: Bool, for key: String) -> Bool {
        let data = Data([value ? 1 : 0])
        return save(data, for: key)
    }

    func loadBool(for key: String) -> Bool {
        guard let data = load(for: key), let first = data.first else { return false }
        return first == 1
    }

    // MARK: - Convenience (String)

    func saveString(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(data, for: key)
    }

    func loadString(for key: String) -> String? {
        guard let data = load(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Convenience (Int)

    func saveInt(_ value: Int, for key: String) -> Bool {
        let data = withUnsafeBytes(of: value) { Data($0) }
        return save(data, for: key)
    }

    func loadInt(for key: String) -> Int? {
        guard let data = load(for: key) else { return nil }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }
}
