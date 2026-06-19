import XCTest
@testable import Tuck

final class CLITestTooltipPresentationTests: XCTestCase {
    func testAvailableTooltipDoesNotCaptureClicksAndUsesOpaqueBackground() {
        let presentation = CLITestTooltipPresentation(state: .available)

        XCTAssertFalse(presentation.allowsHitTesting)
        XCTAssertEqual(presentation.backgroundAlpha, 1.0)
    }

    func testAvailableTooltipSuppressesQuickCaptureFocusRing() {
        let presentation = CLITestTooltipPresentation(state: .available)

        XCTAssertTrue(presentation.suppressesQuickCaptureFocusRing)
    }

    func testUnavailableTooltipCanCaptureClicksForCopyAction() {
        let presentation = CLITestTooltipPresentation(state: .unavailable("boom"))

        XCTAssertTrue(presentation.allowsHitTesting)
        XCTAssertEqual(presentation.backgroundAlpha, 1.0)
        XCTAssertTrue(presentation.suppressesQuickCaptureFocusRing)
    }
}
