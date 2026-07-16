import SwiftUI

@main
struct StoreSwitchApp: App {
    @StateObject private var accountStore = AccountStore.live()

    var body: some Scene {
        WindowGroup {
            RootView(accountStore: accountStore)
                .frame(minWidth: 860, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(L10n.addAccount) {
                    NotificationCenter.default.post(name: .createStoreAccount, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let createStoreAccount = Notification.Name("StoreSwitch.createAccount")
}
