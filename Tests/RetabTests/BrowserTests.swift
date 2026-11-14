import XCTest
@testable import Retab

final class BrowserTests: XCTestCase {
    func testChromeIsListedFirst() {
        XCTAssertEqual(Browser.supported.first, .chrome)
    }

    func testBundleIdentifiersAreUnique() {
        let identifiers = Browser.supported.map(\.bundleIdentifier)
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
    }

    func testLooksUpBrowserByBundleIdentifier() {
        XCTAssertEqual(Browser.withBundleIdentifier("com.brave.Browser"), .brave)
        XCTAssertEqual(Browser.withBundleIdentifier("com.apple.Safari"), .safari)
    }

    func testUnknownBundleIdentifierIsNotSupported() {
        XCTAssertNil(Browser.withBundleIdentifier("org.mozilla.firefox"))
    }

    func testSafariUsesItsOwnScriptingFamily() {
        XCTAssertEqual(Browser.safari.scriptingFamily, .safari)
        for browser in Browser.supported where browser != .safari {
            XCTAssertEqual(browser.scriptingFamily, .chromium, "\(browser.name) should script like Chrome")
        }
    }
}
