import XCTest
@testable import StoreSwitch

final class AppleScriptTemplateRendererTests: XCTestCase {
    func testLiveBundleContainsReadableTemplate() throws {
        let renderer = try AppleScriptTemplateRenderer.live()
        let source = try renderer.render(
            credentials: AccountCredentials(appleID: "test@example.com", password: "test-password")
        )
        XCTAssertTrue(source.contains("test@example.com"))
        XCTAssertTrue(source.contains("test-password"))
    }

    func testRenderEscapesCredentialsAndRemovesPlaceholders() throws {
        let renderer = AppleScriptTemplateRenderer(
            template: "set account to \"__STORE_SWITCH_APPLE_ID__\"\nset password to \"__STORE_SWITCH_PASSWORD__\""
        )
        let source = try renderer.render(
            credentials: AccountCredentials(
                appleID: "name+\"test\"@example.com",
                password: "a\\b\"c\nline"
            )
        )

        XCTAssertFalse(source.contains(AppleScriptTemplateRenderer.appleIDPlaceholder))
        XCTAssertFalse(source.contains(AppleScriptTemplateRenderer.passwordPlaceholder))
        XCTAssertTrue(source.contains("name+\\\"test\\\"@example.com"))
        XCTAssertTrue(source.contains("a\\\\b\\\"c\\nline"))
    }

    func testInvalidTemplateFailsBeforeAutomation() {
        let renderer = AppleScriptTemplateRenderer(template: "return 1")
        XCTAssertThrowsError(
            try renderer.render(credentials: AccountCredentials(appleID: "x", password: "y"))
        )
    }
}
