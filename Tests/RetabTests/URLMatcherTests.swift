import XCTest
@testable import Retab

final class URLMatcherTests: XCTestCase {

    private func tab(_ url: String, index: Int = 1) -> BrowserTab {
        BrowserTab(window: 1, tab: index, url: url)
    }

    private func match(_ link: String, against urls: [String]) -> BrowserTab? {
        let tabs = urls.enumerated().map { tab($0.element, index: $0.offset + 1) }
        return URLMatcher.firstMatch(for: URL(string: link)!, in: tabs)
    }

    func testIdenticalURLsMatch() {
        XCTAssertEqual(match("https://example.com/docs", against: ["https://example.com/docs"])?.tab, 1)
    }

    func testReturnsFirstMatchingTab() {
        let result = match("https://example.com/a", against: [
            "https://example.com/b",
            "https://example.com/a",
            "https://example.com/a",
        ])
        XCTAssertEqual(result?.tab, 2)
    }

    func testFragmentIsIgnored() {
        XCTAssertNotNil(match("https://example.com/a#intro", against: ["https://example.com/a"]))
        XCTAssertNotNil(match("https://example.com/a", against: ["https://example.com/a#section"]))
    }

    func testTrackingParametersAreIgnored() {
        XCTAssertNotNil(match(
            "https://example.com/a?utm_source=slack&id=2",
            against: ["https://example.com/a?id=2"]
        ))
        XCTAssertNotNil(match(
            "https://example.com/a?fbclid=abc123",
            against: ["https://example.com/a"]
        ))
    }

    func testTrackingParameterNamesAreCaseInsensitive() {
        XCTAssertNotNil(match("https://example.com/a?UTM_Source=x", against: ["https://example.com/a"]))
    }

    func testMeaningfulQueryParametersMustMatch() {
        XCTAssertNil(match("https://example.com/a?id=1", against: ["https://example.com/a?id=2"]))
        XCTAssertNil(match("https://example.com/a?id=1", against: ["https://example.com/a"]))
    }

    func testHostIsCaseInsensitive() {
        XCTAssertNotNil(match("https://EXAMPLE.com/a", against: ["https://example.COM/a"]))
    }

    func testTrailingSlashIsIgnored() {
        XCTAssertNotNil(match("https://example.com/docs/", against: ["https://example.com/docs"]))
    }

    func testRootPathIsPreserved() {
        XCTAssertNotNil(match("https://example.com/", against: ["https://example.com"]))
    }

    func testDifferentPathDoesNotMatch() {
        XCTAssertNil(match("https://example.com/a", against: ["https://example.com/b"]))
    }

    func testSchemeMustMatch() {
        XCTAssertNil(match("http://example.com/a", against: ["https://example.com/a"]))
    }

    func testNonWebTabsAreIgnored() {
        XCTAssertNil(match("https://example.com/", against: ["chrome://newtab/", ""]))
    }

    func testNormalizeRejectsNonWebURLs() {
        XCTAssertNil(URLMatcher.normalized("chrome://settings"))
        XCTAssertNil(URLMatcher.normalized("file:///Users/someone/doc.html"))
    }
}
