import Foundation

enum AppleScriptTemplateError: LocalizedError {
    case resourceMissing
    case unreadableResource
    case invalidTemplate

    var errorDescription: String? {
        switch self {
        case .resourceMissing: return "没有找到 App Store 自动化脚本资源。"
        case .unreadableResource: return "无法读取 App Store 自动化脚本资源。"
        case .invalidTemplate: return "App Store 自动化脚本模板不完整。"
        }
    }
}

struct AppleScriptTemplateRenderer {
    static let appleIDPlaceholder = "__STORE_SWITCH_APPLE_ID__"
    static let passwordPlaceholder = "__STORE_SWITCH_PASSWORD__"

    private let template: String

    init(template: String) {
        self.template = template
    }

    static func live(bundle: Bundle = .main) throws -> AppleScriptTemplateRenderer {
        if let sourceURL = bundle.url(forResource: "SwitchAppStoreAccount", withExtension: "applescript"),
           let template = try? String(contentsOf: sourceURL, encoding: .utf8) {
            return AppleScriptTemplateRenderer(template: template)
        }

        guard let compiledURL = bundle.url(forResource: "SwitchAppStoreAccount", withExtension: "scpt") else {
            throw AppleScriptTemplateError.resourceMissing
        }
        var errorInfo: NSDictionary?
        guard let compiledScript = NSAppleScript(contentsOf: compiledURL, error: &errorInfo),
              let template = compiledScript.source
        else {
            throw AppleScriptTemplateError.unreadableResource
        }
        return AppleScriptTemplateRenderer(template: template)
    }

    func render(credentials: AccountCredentials) throws -> String {
        guard template.contains(Self.appleIDPlaceholder),
              template.contains(Self.passwordPlaceholder)
        else {
            throw AppleScriptTemplateError.invalidTemplate
        }

        return template
            .replacingOccurrences(of: Self.appleIDPlaceholder, with: Self.escape(credentials.appleID))
            .replacingOccurrences(of: Self.passwordPlaceholder, with: Self.escape(credentials.password))
    }

    static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
