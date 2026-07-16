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
                    Label("新增账号", systemImage: "plus")
                }
            }
        }
        .sheet(item: $editorContext) { context in
            AccountEditorView(
                title: context.account == nil ? "新增 App Store 账号" : "编辑 App Store 账号",
                initialDraft: context.draft,
                initialMessage: context.initialMessage,
                onSave: { draft in
                    let saved = try accountStore.save(draft, editing: context.account)
                    selection = saved.id
                }
            )
        }
        .alert("确认删除账号？", isPresented: deleteAlertBinding, presenting: pendingDelete) { account in
            Button("删除", role: .destructive) { delete(account) }
            Button("取消", role: .cancel) { pendingDelete = nil }
        } message: { account in
            Text("会同时删除“\(account.displayName)”保存在钥匙串里的 Apple ID 和密码，此操作无法撤销。")
        }
        .alert("切换 App Store 账号？", isPresented: switchAlertBinding, presenting: pendingSwitch) { account in
            Button("开始切换") { switchAccount(account) }
            Button("取消", role: .cancel) { pendingSwitch = nil }
        } message: { account in
            Text("StoreSwitch 会退出当前 App Store 账号，并登录“\(account.displayName)”（\(account.regionName)）。如果出现双重认证或条款页面，需要你手动完成。")
        }
        .alert(item: $notice) { notice in
            Alert(title: Text(notice.title), message: Text(notice.message), dismissButton: .default(Text("好")))
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
            Section("App Store 账号") {
                ForEach(accountStore.accounts) { account in
                    AccountRow(account: account)
                        .tag(account.id)
                        .contextMenu {
                            Button("编辑") { edit(account) }
                            Button("删除", role: .destructive) { pendingDelete = account }
                        }
                }
            }
        }
        .overlay {
            if accountStore.accounts.isEmpty {
                ContentUnavailableView {
                    Label("还没有账号", systemImage: "person.crop.circle.badge.plus")
                } description: {
                    Text("添加账号后，密码只会保存在 macOS 钥匙串。")
                } actions: {
                    Button("添加第一个账号") {
                        editorContext = EditorContext(account: nil, draft: AccountDraft())
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
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
            ContentUnavailableView("选择一个账号", systemImage: "person.crop.circle")
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
                notice = SwitchNotice(title: "无法读取账号", message: error.localizedDescription)
            }
        }
    }

    private func delete(_ account: StoreAccount) {
        do {
            try accountStore.delete(account)
            pendingDelete = nil
        } catch {
            notice = SwitchNotice(title: "删除失败", message: error.localizedDescription)
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
                notice = SwitchNotice(title: "无法读取账号", message: error.localizedDescription)
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
                        title: "切换流程完成",
                        message: "App Store 已提交“\(account.displayName)”的登录。如果左下角显示该账号，就已经成功。"
                    )
                case .needsAttention:
                    notice = SwitchNotice(
                        title: "需要手动确认",
                        message: "App Store 仍显示验证窗口，请完成双重认证、条款确认或安全验证。"
                    )
                }
            } catch {
                notice = SwitchNotice(title: "无法切换", message: error.localizedDescription)
            }
        }
    }

    private func recoveryEditorContext(for account: StoreAccount) -> EditorContext {
        EditorContext(
            account: account,
            draft: AccountDraft(account: account),
            initialMessage: "旧版临时签名创建的钥匙串凭据已无法读取。请重新输入 Apple ID 和密码并保存一次；升级到稳定签名后，后续重装不会再丢失访问权限。"
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
                        Label("凭据保存在 macOS 钥匙串", systemImage: "lock.shield.fill")
                            .font(.callout)
                            .foregroundStyle(.green)
                    }
                }

                GroupBox("备注") {
                    Text(account.note.isEmpty ? "没有备注" : account.note)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(account.note.isEmpty ? .secondary : .primary)
                        .padding(.vertical, 6)
                }

                GroupBox("切换时会发生什么") {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("打开 App Store 并退出当前商店账号", systemImage: "rectangle.portrait.and.arrow.right")
                        Label("自动填写所选 Apple ID 与密码", systemImage: "keyboard")
                        Label("双重认证或条款确认仍由你手动完成", systemImage: "checkmark.shield")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }

                HStack {
                    Button(action: onSwitch) {
                        if isSwitching {
                            ProgressView()
                                .controlSize(.small)
                            Text("正在切换…")
                        } else {
                            Label("切换到这个账号", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isSwitching)

                    Button("编辑", action: onEdit)
                        .controlSize(.large)

                    Spacer()

                    Button("删除", role: .destructive, action: onDelete)
                        .controlSize(.large)
                }
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .navigationTitle(account.displayName)
    }
}
