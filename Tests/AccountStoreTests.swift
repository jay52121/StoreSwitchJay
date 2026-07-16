import Foundation
import Security
import XCTest
@testable import StoreSwitch

@MainActor
final class AccountStoreTests: XCTestCase {
    func testSaveAndEditKeepCredentialsOutsideMetadata() throws {
        let metadata = MemoryMetadataStorage()
        let vault = MemoryCredentialVault()
        let store = AccountStore(metadataStorage: metadata, credentialVault: vault)

        var draft = AccountDraft()
        draft.displayName = "美区主账号"
        draft.regionName = "美国"
        draft.regionCode = "us"
        draft.note = "用于下载美区 App"
        draft.appleID = "person@example.com"
        draft.password = "secret-value"

        let created = try store.save(draft, editing: nil)
        XCTAssertEqual(store.accounts.count, 1)
        XCTAssertEqual(store.accounts[0].regionCode, "US")
        XCTAssertEqual(try vault.read(for: created.id), AccountCredentials(appleID: "person@example.com", password: "secret-value"))

        let encodedMetadata = try JSONEncoder().encode(metadata.accounts)
        let metadataText = String(decoding: encodedMetadata, as: UTF8.self)
        XCTAssertFalse(metadataText.contains("person@example.com"))
        XCTAssertFalse(metadataText.contains("secret-value"))

        draft.note = "更新后的备注"
        draft.password = "new-secret"
        let edited = try store.save(draft, editing: created)
        XCTAssertEqual(edited.id, created.id)
        XCTAssertEqual(store.accounts[0].note, "更新后的备注")
        XCTAssertEqual(try vault.read(for: created.id).password, "new-secret")
    }

    func testDeleteRemovesMetadataAndCredentials() throws {
        let metadata = MemoryMetadataStorage()
        let vault = MemoryCredentialVault()
        let store = AccountStore(metadataStorage: metadata, credentialVault: vault)

        var draft = AccountDraft()
        draft.displayName = "国区"
        draft.regionName = "中国大陆"
        draft.regionCode = "CN"
        draft.appleID = "person@example.com"
        draft.password = "secret"
        let account = try store.save(draft, editing: nil)

        try store.delete(account)
        XCTAssertTrue(store.accounts.isEmpty)
        XCTAssertThrowsError(try vault.read(for: account.id))
    }

    func testDeleteAllowsLegacyMetadataWithoutReadableCredentials() throws {
        let account = StoreAccount(
            displayName: "旧账号",
            regionName: "美国",
            regionCode: "US",
            note: ""
        )
        let metadata = MemoryMetadataStorage()
        metadata.accounts = [account]
        let store = AccountStore(
            metadataStorage: metadata,
            credentialVault: MemoryCredentialVault()
        )

        try store.delete(account)

        XCTAssertTrue(store.accounts.isEmpty)
        XCTAssertTrue(metadata.accounts.isEmpty)
    }

    func testAuthenticationFailureOffersCredentialReplacement() {
        XCTAssertTrue(CredentialVaultError.notFound.canRecoverByReplacingCredentials)
        XCTAssertTrue(CredentialVaultError.keychain(errSecAuthFailed).canRecoverByReplacingCredentials)
        XCTAssertFalse(CredentialVaultError.keychain(errSecParam).canRecoverByReplacingCredentials)
    }

    func testValidationRejectsMissingPassword() {
        let store = AccountStore(
            metadataStorage: MemoryMetadataStorage(),
            credentialVault: MemoryCredentialVault()
        )
        var draft = AccountDraft()
        draft.displayName = "测试"
        draft.regionName = "日本"
        draft.appleID = "person@example.com"

        XCTAssertThrowsError(try store.save(draft, editing: nil)) { error in
            XCTAssertEqual(error.localizedDescription, AccountStoreError.missingPassword.localizedDescription)
        }
    }
}

private final class MemoryMetadataStorage: AccountMetadataStoring {
    var accounts: [StoreAccount] = []

    func load() throws -> [StoreAccount] { accounts }
    func save(_ accounts: [StoreAccount]) throws { self.accounts = accounts }
}

private final class MemoryCredentialVault: CredentialVaulting {
    private var values: [UUID: AccountCredentials] = [:]

    func save(_ credentials: AccountCredentials, for id: UUID) throws {
        values[id] = credentials
    }

    func read(for id: UUID) throws -> AccountCredentials {
        guard let credentials = values[id] else { throw CredentialVaultError.notFound }
        return credentials
    }

    func delete(for id: UUID) throws {
        values[id] = nil
    }
}
