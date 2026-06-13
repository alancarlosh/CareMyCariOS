import Foundation
import Security

final class KeychainTokenStore {
    static let shared = KeychainTokenStore()

    private let service = "com.itsm.caremycar.ios.auth"
    private let tokenAccount = "access_token"
    private let userRoleAccount = "user_role"
    private let userAccount = "user"

    private init() {}

    func save(token: String, user: User) {
        set(token, account: tokenAccount)
        if let userData = try? JSONEncoder().encode(user) {
            set(userData, account: userAccount)
        } else {
            remove(account: userAccount)
        }

        if let role = user.role {
            set(role, account: userRoleAccount)
        } else {
            remove(account: userRoleAccount)
        }
    }

    func getToken() -> String? {
        get(account: tokenAccount)
    }

    func getUserRole() -> String? {
        get(account: userRoleAccount)
    }

    func getUser() -> User? {
        guard let data = getData(account: userAccount) else {
            return nil
        }

        return try? JSONDecoder().decode(User.self, from: data)
    }

    func clear() {
        remove(account: tokenAccount)
        remove(account: userRoleAccount)
        remove(account: userAccount)
    }

    private func set(_ value: String, account: String) {
        set(Data(value.utf8), account: account)
    }

    private func set(_ data: Data, account: String) {
        remove(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(account: String) -> String? {
        guard let data = getData(account: account) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func getData(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard
            status == errSecSuccess,
            let data = item as? Data
        else {
            return nil
        }

        return data
    }

    private func remove(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}
