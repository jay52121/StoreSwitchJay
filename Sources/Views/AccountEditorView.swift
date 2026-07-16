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
                    Text(L10n.keychainEditorDescription)
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
                Section(L10n.displayInformation) {
                    TextField(L10n.displayNamePlaceholder, text: $draft.displayName)
                    TextField(L10n.regionNamePlaceholder, text: $draft.regionName)
                    TextField(L10n.regionCodePlaceholder, text: $draft.regionCode)
                }

                Section(L10n.signInCredentials) {
                    TextField("Apple ID", text: $draft.appleID)
                        .textContentType(.username)
                    SecureField(L10n.password, text: $draft.password)
                        .textContentType(.password)
                }

                Section(L10n.notes) {
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
                Button(L10n.cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.save) { save() }
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
