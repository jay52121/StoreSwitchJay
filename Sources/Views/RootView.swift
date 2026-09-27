import SwiftUI

private struct EditorContext: Identifiable {
    let id = UUID()
    let account: StoreAccount?
    let draft: AccountDraft
    let initialMessage: String?

    init(account: StoreAccount?, draft: AccountDraft, initialMessage: String? = nil) {
        self.account = account
        self.draft = draft
        self.initialMessage = initialMessage
    }
}

private struct SwitchNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct RootView: View {
    @ObservedObject var accountStore: AccountStore

    @State private var selection: StoreAccount.ID?
    @State private var editorContext: EditorContext?
    @State private var pendingDelete: StoreAccount?
    @State private var pendingSwitch: StoreAccount?
    @State private var notice: SwitchNotice?
    @State private var isSwitching = false

    var selectedAccount: StoreAccount? {
        guard let selection else { return accountStore.accounts.first }
        return accountStore.accounts.first { $0.id == selection }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 250, ideal: 290, max: 360)
        } detail: {
            detail
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorContext = EditorContext(account: nil, draft: AccountDraft())
                } label: {
                    Label(L10n.addAccount, systemImage: "plus")
                }
            }
        }
        .sheet(item: $editorContext) { context in
            AccountEditorView(
                title: context.account == nil ? L10n.addAccountTitle : L10n.editAccountTitle,
                initialDraft: context.draft,
                initialMessage: context.initialMessage,
                onSave: { draft in
                    let saved = try accountStore.save(draft, editing: context.account)
                    selection = saved.id
                }
            )
        }
        .alert(L10n.deleteConfirmationTitle, isPresented: deleteAlertBinding, presenting: pendingDelete) { account in
            Button(L10n.delete, role: .destructive) { delete(account) }
            Button(L10n.cancel, role: .cancel) { pendingDelete = nil }
        } message: { account in
            Text(L10n.deleteConfirmationMessage(accountName: account.displayName))
        }
        .alert(L10n.switchConfirmationTitle, isPresented: switchAlertBinding, presenting: pendingSwitch) { account in
            Button(L10n.startSwitching) { switchAccount(account) }
            Button(L10n.cancel, role: .cancel) { pendingSwitch = nil }
        } message: { account in
            Text(L10n.switchConfirmationMessage(accountName: account.displayName, regionName: account.regionName))
        }
        .alert(item: $notice) { notice in
            Alert(title: Text(notice.title), message: Text(notice.message), dismissButton: .default(Text(L10n.okay)))
        }
        .onReceive(NotificationCenter.default.publisher(for: .createStoreAccount)) { _ in
            editorContext = EditorContext(account: nil, draft: AccountDraft())
        }
        .onChange(of: accountStore.accounts) { _, accounts in
            if let selection, !accounts.contains(where: { $0.id == selection }) {
                self.selection = accounts.first?.id
            } else if selection == nil {
                selection = accounts.first?.id
            }
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section(L10n.accountList) {
                ForEach(accountStore.accounts) { account in
                    AccountRow(account: account)
                        .tag(account.id)
                        .contextMenu {
                            Button(L10n.edit) { edit(account) }
                            Button(L10n.delete, role: .destructive) { pendingDelete = account }
                        }
                }
            }
        }
        .overlay {
            if accountStore.accounts.isEmpty {
                ContentUnavailableView {
                    Label(L10n.noAccounts, systemImage: "person.crop.circle.badge.plus")
                } description: {
                    Text(L10n.noAccountsDescription)
                } actions: {
                    Button(L10n.addFirstAccount) {
                        editorContext = EditorContext(account: nil, draft: AccountDraft())
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("StoreSwitch (jay)")
    }

    @ViewBuilder
    private var detail: some View {
        if let account = selectedAccount {
            AccountDetailView(
                account: account,
                isSwitching: isSwitching,
                onSwitch: { pendingSwitch = account },
                onEdit: { edit(account) },
                onDelete: { pendingDelete = account }
            )
        } else {
            ContentUnavailableView(L10n.selectAccount, systemImage: "person.crop.circle")
                .navigationTitle("StoreSwitch (jay)")
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private var switchAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingSwitch != nil },
            set: { if !$0 { pendingSwitch = nil } }
        )
    }

    private func edit(_ account: StoreAccount) {
        do {
            let credentials = try accountStore.credentials(for: account)
            editorContext = EditorContext(account: account, draft: AccountDraft(account: account, credentials: credentials))
        } catch {
            if let vaultError = error as? CredentialVaultError,
               vaultError.canRecoverByReplacingCredentials {
                editorContext = recoveryEditorContext(for: account)
            } else {
                notice = SwitchNotice(title: L10n.unableToReadAccount, message: error.localizedDescription)
            }
        }
    }

    private func delete(_ account: StoreAccount) {
        do {
            try accountStore.delete(account)
            pendingDelete = nil
        } catch {
            notice = SwitchNotice(title: L10n.deleteFailed, message: error.localizedDescription)
        }
    }

    private func switchAccount(_ account: StoreAccount) {
        pendingSwitch = nil
        let credentials: AccountCredentials
        do {
            credentials = try accountStore.credentials(for: account)
        } catch {
            if let vaultError = error as? CredentialVaultError,
               vaultError.canRecoverByReplacingCredentials {
                editorContext = recoveryEditorContext(for: account)
            } else {
                notice = SwitchNotice(title: L10n.unableToReadAccount, message: error.localizedDescription)
            }
            return
        }

        isSwitching = true

        Task {
            defer { isSwitching = false }
            do {
                let automation = try AppStoreAutomation.live()
                let result = try await automation.switchAccount(using: credentials)
                switch result {
                case .completed:
                    notice = SwitchNotice(
                        title: L10n.switchCompletedTitle,
                        message: L10n.switchCompletedMessage(accountName: account.displayName)
                    )
                case .needsAttention:
                    notice = SwitchNotice(
                        title: L10n.manualConfirmationTitle,
                        message: L10n.manualConfirmationMessage
                    )
                }
            } catch {
                notice = SwitchNotice(title: L10n.unableToSwitch, message: error.localizedDescription)
            }
        }
    }

    private func recoveryEditorContext(for account: StoreAccount) -> EditorContext {
        EditorContext(
            account: account,
            draft: AccountDraft(account: account),
            initialMessage: L10n.credentialRecoveryMessage
        )
    }
}

private struct AccountRow: View {
    let account: StoreAccount

    var body: some View {
        HStack(spacing: 11) {
            Text(account.regionBadge)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 42, height: 30)
                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(.headline)
                    .lineLimit(1)
                Text(account.regionName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AccountDetailView: View {
    let account: StoreAccount
    let isSwitching: Bool
    let onSwitch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top, spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.blue.gradient)
                        Text(account.regionBadge)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    .frame(width: 82, height: 82)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(account.displayName)
                            .font(.largeTitle.bold())
                        Text(account.regionName)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Label(L10n.credentialsInKeychain, systemImage: "lock.shield.fill")
                            .font(.callout)
                            .foregroundStyle(.green)
                    }
                }

                GroupBox(L10n.notes) {
                    Text(account.note.isEmpty ? L10n.noNotes : account.note)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(account.note.isEmpty ? .secondary : .primary)
                        .padding(.vertical, 6)
                }

                GroupBox(L10n.switchExplanationTitle) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(L10n.switchStepOpen, systemImage: "rectangle.portrait.and.arrow.right")
                        Label(L10n.switchStepFill, systemImage: "keyboard")
                        Label(L10n.switchStepManual, systemImage: "checkmark.shield")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }

                HStack {
                    Button(action: onSwitch) {
                        if isSwitching {
                            ProgressView()
                                .controlSize(.small)
                            Text(L10n.switching)
                        } else {
                            Label(L10n.switchToAccount, systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSwitching)

                    Button(L10n.edit, action: onEdit)
                        .controlSize(.large)

                    Spacer()

                    Button(L10n.delete, role: .destructive, action: onDelete)
                        .controlSize(.large)
                }
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .navigationTitle("\(account.displayName) — StoreSwitch (jay)")
    }
}
