import Foundation
import Security

protocol CredentialVaulting {
    func save(_ credentials: AccountCredentials, for id: UUID) throws
    func read(for id: UUID) throws -> AccountCredentials
    func delete(for id: UUID) throws
}

enum CredentialVaultError: LocalizedError {
    case notFound
    case invalidData
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "没有找到这个账号的钥匙串凭据。"
        case .invalidData:
            return "钥匙串里的账号数据无法读取。"
        case .keychain(let status):
            let detail = SecCopyErrorMessageString(status, nil) as String? ?? "未知错误"
            return "钥匙串操作失败：\(detail)（\(status)）"
        }
    }

    var canRecoverByReplacingCredentials: Bool {
        switch self {
        case .notFound, .invalidData:
            return true
        case .keychain(let status):
            return status == errSecAuthFailed
        }
    }
}

struct KeychainCredentialVault: CredentialVaulting {
    private let service: String

    init(service: String = "com.jplinx.storeswitch.credentials.v2") {
        self.service = service
    }

    func save(_ credentials: AccountCredentials, for id: UUID) throws {
        let data = try JSONEncoder().encode(credentials)
        let query = baseQuery(for: id)
        let update: [CFString: Any] = [kSecValueData: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)

        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else {
            throw CredentialVaultError.keychain(status)
        }

        var item = query
        item[kSecValueData] = data
        item[kSecAttrLabel] = "StoreSwitch App Store account"
        item[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlocked
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw CredentialVaultError.keychain(addStatus)
        }
    }

    func read(for id: UUID) throws -> AccountCredentials {
        var query = baseQuery(for: id)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { throw CredentialVaultError.notFound }
        guard status == errSecSuccess else {
            throw CredentialVaultError.keychain(status)
        }
        guard let data = item as? Data,
              let credentials = try? JSONDecoder().decode(AccountCredentials.self, from: data)
        else {
            throw CredentialVaultError.invalidData
        }
        return credentials
    }

    func delete(for id: UUID) throws {
        let status = SecItemDelete(baseQuery(for: id) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialVaultError.keychain(status)
        }
    }

    private func baseQuery(for id: UUID) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: id.uuidString
        ]
    }
}
