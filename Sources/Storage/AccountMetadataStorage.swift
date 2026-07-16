import Foundation

protocol AccountMetadataStoring {
    func load() throws -> [StoreAccount]
    func save(_ accounts: [StoreAccount]) throws
}

struct UserDefaultsAccountMetadataStorage: AccountMetadataStoring {
    private let defaults: UserDefaults
    private let key: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        key: String = "storeAccounts.v1"
    ) {
        self.defaults = defaults
        self.key = key

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func load() throws -> [StoreAccount] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return try decoder.decode([StoreAccount].self, from: data)
    }

    func save(_ accounts: [StoreAccount]) throws {
        defaults.set(try encoder.encode(accounts), forKey: key)
    }
}
