import Foundation

enum AccountStoreError: LocalizedError {
    case missingDisplayName
    case missingRegion
    case missingAppleID
    case missingPassword

    var errorDescription: String? {
        switch self {
        case .missingDisplayName: return "请填写账号名称。"
        case .missingRegion: return "请填写地区名称。"
        case .missingAppleID: return "请填写 Apple ID。"
        case .missingPassword: return "请填写密码。"
        }
    }
}

@MainActor
final class AccountStore: ObservableObject {
    @Published private(set) var accounts: [StoreAccount] = []

    private let metadataStorage: AccountMetadataStoring
    private let credentialVault: CredentialVaulting

    init(
        metadataStorage: AccountMetadataStoring,
        credentialVault: CredentialVaulting
    ) {
        self.metadataStorage = metadataStorage
        self.credentialVault = credentialVault
        accounts = (try? metadataStorage.load()) ?? []
        sortAccounts()
    }

    static func live() -> AccountStore {
        AccountStore(
            metadataStorage: UserDefaultsAccountMetadataStorage(),
            credentialVault: KeychainCredentialVault()
        )
    }

    func credentials(for account: StoreAccount) throws -> AccountCredentials {
        try credentialVault.read(for: account.id)
    }

    @discardableResult
    func save(_ draft: AccountDraft, editing existing: StoreAccount?) throws -> StoreAccount {
        let draft = draft.normalized
        try validate(draft)

        let previousAccounts = accounts
        let oldCredentials = existing.flatMap { try? credentialVault.read(for: $0.id) }
        let now = Date()
        let account = StoreAccount(
            id: existing?.id ?? UUID(),
            displayName: draft.displayName,
            regionName: draft.regionName,
            regionCode: draft.regionCode,
            note: draft.note,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now
        )
        let credentials = AccountCredentials(appleID: draft.appleID, password: draft.password)

        try credentialVault.save(credentials, for: account.id)
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        sortAccounts()

        do {
            try metadataStorage.save(accounts)
            return account
        } catch {
            accounts = previousAccounts
            if let oldCredentials {
                try? credentialVault.save(oldCredentials, for: account.id)
            } else {
                try? credentialVault.delete(for: account.id)
            }
            throw error
        }
    }

    func delete(_ account: StoreAccount) throws {
        let previousAccounts = accounts
        let credentials: AccountCredentials?
        do {
            credentials = try credentialVault.read(for: account.id)
        } catch let vaultError as CredentialVaultError where vaultError.canRecoverByReplacingCredentials {
            credentials = nil
        }
        try credentialVault.delete(for: account.id)
        accounts.removeAll { $0.id == account.id }

        do {
            try metadataStorage.save(accounts)
        } catch {
            accounts = previousAccounts
            if let credentials {
                try? credentialVault.save(credentials, for: account.id)
            }
            throw error
        }
    }

    private func validate(_ draft: AccountDraft) throws {
        if draft.displayName.isEmpty { throw AccountStoreError.missingDisplayName }
        if draft.regionName.isEmpty { throw AccountStoreError.missingRegion }
        if draft.appleID.isEmpty { throw AccountStoreError.missingAppleID }
        if draft.password.isEmpty { throw AccountStoreError.missingPassword }
    }

    private func sortAccounts() {
        accounts.sort {
            if $0.regionName.localizedStandardCompare($1.regionName) == .orderedSame {
                return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
            return $0.regionName.localizedStandardCompare($1.regionName) == .orderedAscending
        }
    }
}
