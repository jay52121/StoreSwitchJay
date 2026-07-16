import Foundation
import XCTest
@testable import StoreSwitch

final class LocalizationTests: XCTestCase {
    func testEnglishResourcesAreComplete() throws {
        let bundle = try localizedBundle(language: "en")

        XCTAssertEqual(bundle.localizedString(forKey: "account.add", value: nil, table: nil), "Add Account")
        XCTAssertEqual(bundle.localizedString(forKey: "switch.failed.title", value: nil, table: nil), "Unable to Switch")
        XCTAssertEqual(
            bundle.localizedString(forKey: "error.automation.execution", value: nil, table: nil),
            "Switch failed: %@"
        )
    }

    func testSimplifiedChineseResourcesAreComplete() throws {
        let bundle = try localizedBundle(language: "zh-Hans")

        XCTAssertEqual(bundle.localizedString(forKey: "account.add", value: nil, table: nil), "新增账号")
        XCTAssertEqual(bundle.localizedString(forKey: "switch.failed.title", value: nil, table: nil), "无法切换")
        XCTAssertEqual(
            bundle.localizedString(forKey: "error.automation.execution", value: nil, table: nil),
            "切换失败：%@"
        )
    }

    func testLocalizedAppleEventsUsageDescriptionsExist() throws {
        let englishBundle = try localizedBundle(language: "en")
        let chineseBundle = try localizedBundle(language: "zh-Hans")

        XCTAssertTrue(
            englishBundle.localizedString(
                forKey: "NSAppleEventsUsageDescription",
                value: nil,
                table: "InfoPlist"
            ).contains("System Events")
        )
        XCTAssertTrue(
            chineseBundle.localizedString(
                forKey: "NSAppleEventsUsageDescription",
                value: nil,
                table: "InfoPlist"
            ).contains("系统事件")
        )
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let url = try XCTUnwrap(Bundle.main.url(forResource: language, withExtension: "lproj"))
        return try XCTUnwrap(Bundle(url: url))
    }
}
