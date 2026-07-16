import SwiftUI

struct AccountEditorView: View {
    let title: String
    let onSave: (AccountDraft) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: AccountDraft
    @State private var errorMessage: String?

    init(
        title: String,
        initialDraft: AccountDraft,
        initialMessage: String? = nil,
        onSave: @escaping (AccountDraft) throws -> Void
    ) {
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: initialDraft)
        _errorMessage = State(initialValue: initialMessage)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.bold())
                    Text("Apple ID 与密码会加密保存在 macOS 钥匙串。")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.green)
            }
            .padding(24)

            Divider()

            Form {
                Section("显示信息") {
                    TextField("账号名称，例如：美区主账号", text: $draft.displayName)
                    TextField("地区名称，例如：美国", text: $draft.regionName)
                    TextField("地区代码，例如：US", text: $draft.regionCode)
                }

                Section("登录凭据") {
                    TextField("Apple ID", text: $draft.appleID)
                        .textContentType(.username)
                    SecureField("密码", text: $draft.password)
                        .textContentType(.password)
                }

                Section("备注") {
                    TextEditor(text: $draft.note)
                        .frame(minHeight: 80)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("保存") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(18)
        }
        .frame(width: 560, height: 600)
    }

    private func save() {
        do {
            try onSave(draft)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
