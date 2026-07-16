import Foundation
import Security

enum L10n {
    private static func text(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    }

    private static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }

    static let addAccount = text("account.add")
    static let addAccountTitle = text("account.add.title")
    static let editAccountTitle = text("account.edit.title")
    static let accountList = text("account.list")
    static let noAccounts = text("account.none.title")
    static let noAccountsDescription = text("account.none.description")
    static let addFirstAccount = text("account.add.first")
    static let selectAccount = text("account.select")

    static let edit = text("common.edit")
    static let delete = text("common.delete")
    static let cancel = text("common.cancel")
    static let save = text("common.save")
    static let okay = text("common.okay")

    static let keychainEditorDescription = text("editor.keychain.description")
    static let displayInformation = text("editor.display.information")
    static let displayNamePlaceholder = text("editor.display.name.placeholder")
    static let regionNamePlaceholder = text("editor.region.name.placeholder")
    static let regionCodePlaceholder = text("editor.region.code.placeholder")
    static let signInCredentials = text("editor.credentials")
    static let password = text("editor.password")
    static let notes = text("editor.notes")

    static let deleteConfirmationTitle = text("delete.confirmation.title")
    static func deleteConfirmationMessage(accountName: String) -> String {
        format("delete.confirmation.message", accountName)
    }

    static let switchConfirmationTitle = text("switch.confirmation.title")
    static let startSwitching = text("switch.start")
    static func switchConfirmationMessage(accountName: String, regionName: String) -> String {
        format("switch.confirmation.message", accountName, regionName)
    }

    static let unableToReadAccount = text("account.read.failed.title")
    static let deleteFailed = text("account.delete.failed.title")
    static let switchCompletedTitle = text("switch.completed.title")
    static func switchCompletedMessage(accountName: String) -> String {
        format("switch.completed.message", accountName)
    }
    static let manualConfirmationTitle = text("switch.manual.title")
    static let manualConfirmationMessage = text("switch.manual.message")
    static let unableToSwitch = text("switch.failed.title")
    static let credentialRecoveryMessage = text("credential.recovery.message")

    static let credentialsInKeychain = text("detail.credentials.keychain")
    static let noNotes = text("detail.notes.empty")
    static let switchExplanationTitle = text("detail.switch.explanation.title")
    static let switchStepOpen = text("detail.switch.step.open")
    static let switchStepFill = text("detail.switch.step.fill")
    static let switchStepManual = text("detail.switch.step.manual")
    static let switching = text("detail.switching")
    static let switchToAccount = text("detail.switch.to.account")

    static let missingDisplayName = text("error.account.display_name.missing")
    static let missingRegion = text("error.account.region.missing")
    static let missingAppleID = text("error.account.apple_id.missing")
    static let missingPassword = text("error.account.password.missing")
    static let keychainNotFound = text("error.keychain.not_found")
    static let keychainInvalidData = text("error.keychain.invalid_data")
    static let unknownError = text("error.unknown")
    static func keychainOperationFailed(detail: String, status: OSStatus) -> String {
        format("error.keychain.operation_failed", detail, status)
    }

    static let accessibilityPermissionRequired = text("error.automation.accessibility")
    static let automationScriptCreationFailed = text("error.automation.creation")
    static let unknownAppleScriptError = text("error.automation.unknown_script")
    static func automationExecutionFailed(message: String) -> String {
        format("error.automation.execution", message)
    }
    static let automationResourceMissing = text("error.automation.resource_missing")
    static let automationResourceUnreadable = text("error.automation.resource_unreadable")
    static let automationTemplateInvalid = text("error.automation.template_invalid")
}
