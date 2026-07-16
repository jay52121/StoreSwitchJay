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
            return "需要辅助功能权限。请到“系统设置 → 隐私与安全性 → 辅助功能”允许 StoreSwitch，然后再试一次。"
        case .scriptCreationFailed:
            return "无法创建 App Store 自动化脚本。"
        case .executionFailed(let message):
            return "切换失败：\(message)"
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
                    let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "未知 AppleScript 错误"
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
