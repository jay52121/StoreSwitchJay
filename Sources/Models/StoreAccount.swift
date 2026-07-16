import Foundation

struct StoreAccount: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    var displayName: String
    var regionName: String
    var regionCode: String
    var note: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        regionName: String,
        regionCode: String,
        note: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.regionName = regionName
        self.regionCode = regionCode
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var regionBadge: String {
        let normalized = regionCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return normalized.isEmpty ? "APP" : normalized
    }
}

struct AccountCredentials: Codable, Equatable {
    var appleID: String
    var password: String
}

struct AccountDraft: Equatable {
    var displayName = ""
    var regionName = ""
    var regionCode = ""
    var note = ""
    var appleID = ""
    var password = ""

    init() {}

    init(account: StoreAccount, credentials: AccountCredentials) {
        displayName = account.displayName
        regionName = account.regionName
        regionCode = account.regionCode
        note = account.note
        appleID = credentials.appleID
        password = credentials.password
    }

    init(account: StoreAccount) {
        displayName = account.displayName
        regionName = account.regionName
        regionCode = account.regionCode
        note = account.note
    }

    var normalized: AccountDraft {
        var copy = self
        copy.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.regionName = regionName.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.regionCode = regionCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        copy.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.appleID = appleID.trimmingCharacters(in: .whitespacesAndNewlines)
        return copy
    }
}
