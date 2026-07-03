import XCTest
@testable import MornDash

final class BlockWindowLogicTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return cal
    }

    func testInsideBlockWindow() {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 3
        components.hour = 8
        components.minute = 30
        let now = calendar.date(from: components)!

        XCTAssertTrue(
            BlockWindowLogic.isInBlockWindow(now: now, startHour: 7, startMinute: 0, calendar: calendar)
        )
    }

    func testBeforeStartIsOutsideBlockWindow() {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 3
        components.hour = 6
        components.minute = 59
        let now = calendar.date(from: components)!

        XCTAssertFalse(
            BlockWindowLogic.isInBlockWindow(now: now, startHour: 7, startMinute: 0, calendar: calendar)
        )
    }

    func testAfterEndIsOutsideBlockWindow() {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 3
        components.hour = 23
        components.minute = 59
        components.second = 59
        let atEnd = calendar.date(from: components)!

        XCTAssertTrue(
            BlockWindowLogic.isInBlockWindow(now: atEnd, startHour: 7, startMinute: 0, calendar: calendar)
        )

        components.day = 4
        components.hour = 0
        components.minute = 0
        components.second = 0
        let afterMidnight = calendar.date(from: components)!

        XCTAssertFalse(
            BlockWindowLogic.isInBlockWindow(now: afterMidnight, startHour: 7, startMinute: 0, calendar: calendar)
        )
    }

    func testExactlyAtStartIsInsideBlockWindow() {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 3
        components.hour = 7
        components.minute = 0
        let now = calendar.date(from: components)!

        XCTAssertTrue(
            BlockWindowLogic.isInBlockWindow(now: now, startHour: 7, startMinute: 0, calendar: calendar)
        )
    }
}
