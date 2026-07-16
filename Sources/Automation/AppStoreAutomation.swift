import AppKit
import ApplicationServices
import Foundation

enum AppStoreSwitchResult: Equatable {
    case completed
    case needsAttention
}

enum AppStoreAutomationError: LocalizedError {
    case accessibilityPermissionRequired
    case scriptCreationFailed
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            return L10n.accessibilityPermissionRequired
        case .scriptCreationFailed:
            return L10n.automationScriptCreationFailed
        case .executionFailed(let message):
            return L10n.automationExecutionFailed(message: message)
        }
    }
}

protocol AppStoreAutomating {
    func switchAccount(using credentials: AccountCredentials) async throws -> AppStoreSwitchResult
}

final class AppStoreAutomation: AppStoreAutomating {
    private let queue = DispatchQueue(label: "com.jplinx.storeswitch.automation", qos: .userInitiated)
    private let renderer: AppleScriptTemplateRenderer

    init(renderer: AppleScriptTemplateRenderer) {
        self.renderer = renderer
    }

    static func live() throws -> AppStoreAutomation {
        AppStoreAutomation(renderer: try .live())
    }

    func switchAccount(using credentials: AccountCredentials) async throws -> AppStoreSwitchResult {
        guard AXIsProcessTrusted() else {
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
            throw AppStoreAutomationError.accessibilityPermissionRequired
        }

        let source = try renderer.render(credentials: credentials)
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                guard let script = NSAppleScript(source: source) else {
                    continuation.resume(throwing: AppStoreAutomationError.scriptCreationFailed)
                    return
                }

                var errorInfo: NSDictionary?
                let descriptor = script.executeAndReturnError(&errorInfo)
                if let errorInfo {
                    let message = errorInfo[NSAppleScript.errorMessage] as? String ?? L10n.unknownAppleScriptError
                    continuation.resume(throwing: AppStoreAutomationError.executionFailed(message))
                    return
                }

                let result: AppStoreSwitchResult = descriptor.stringValue == "needs_attention"
                    ? .needsAttention
                    : .completed
                continuation.resume(returning: result)
            }
        }
    }
}
