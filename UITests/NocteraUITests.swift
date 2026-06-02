import XCTest

final class NocteraUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
        // auto-allow any system permission alerts that slip through
        addUIInterruptionMonitor(withDescription: "perm") { alert in
            for label in ["Allow", "OK", "Allow While Using App"] {
                if alert.buttons[label].exists { alert.buttons[label].tap(); return true }
            }
            return false
        }
    }

    func testSeededJournalAndPatterns() {
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Journal"].waitForExistence(timeout: 12))
        app.tabBars.buttons["Patterns"].tap()
        XCTAssertTrue(app.staticTexts["RECURRING SYMBOLS"].waitForExistence(timeout: 6))
    }

    func testCaptureTypingSavesAndReads() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset", "--uitest"]
        app.launch()
        let begin = app.buttons["getStarted"]
        XCTAssertTrue(begin.waitForExistence(timeout: 10)); begin.tap()
        let cap = app.buttons["captureEmpty"]
        XCTAssertTrue(cap.waitForExistence(timeout: 6)); cap.tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 6))
        editor.tap()
        app.typeText("I was being chased up the endless stairs of my old house")
        app.buttons["saveDream"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 8))
    }

    func testCalendarView() {
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Journal"].waitForExistence(timeout: 16))
        app.buttons["Calendar"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["calendarMonth"].waitForExistence(timeout: 6))
    }

    func testEditorAddsTag() {
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Journal"].waitForExistence(timeout: 16))
        app.staticTexts["The House"].firstMatch.tap()
        XCTAssertTrue(app.buttons["editDream"].waitForExistence(timeout: 6)); app.buttons["editDream"].tap()
        let field = app.textFields["Add a person, place or tag"]
        XCTAssertTrue(field.waitForExistence(timeout: 6)); field.tap(); app.typeText("grandma")
        app.buttons["Add"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["grandma"].waitForExistence(timeout: 4))
    }

    func testDreamDetailShowsMemoryCallback() {
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Journal"].waitForExistence(timeout: 16))
        app.staticTexts["The House"].firstMatch.tap()
        // the cross-entry "it remembers you" callback must actually render
        let memory = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'visited you'")).firstMatch
        XCTAssertTrue(memory.waitForExistence(timeout: 6))
    }

    func testDreamWrappedOpens() {
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Patterns"].waitForExistence(timeout: 16))
        app.tabBars.buttons["Patterns"].tap()
        app.staticTexts["Dream Wrapped"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["DREAM WRAPPED"].waitForExistence(timeout: 6))
    }

    func testForgotDreamKeepsHabit() {
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots", "--uitest"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Journal"].waitForExistence(timeout: 16))
        app.buttons["addDream"].tap()
        let forgot = app.buttons["forgotDream"]
        XCTAssertTrue(forgot.waitForExistence(timeout: 6)); forgot.tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 6))
    }

    func testPaywallOpensFromSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()
        let begin = app.buttons["getStarted"]
        XCTAssertTrue(begin.waitForExistence(timeout: 10)); begin.tap()
        app.tabBars.buttons["Settings"].tap()
        let unlock = app.buttons["settingsUnlock"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 6)); unlock.tap()
        XCTAssertTrue(app.buttons["purchasePro"].waitForExistence(timeout: 6))
    }
}
