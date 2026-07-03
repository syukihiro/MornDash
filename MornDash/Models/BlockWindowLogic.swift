import Foundation

/// Pure block-window logic shared by HomeViewModel and unit tests.
enum BlockWindowLogic {
    /// Returns true when `now` is inside the daily block window `[startTime, endTime]` on the same calendar day.
    static func isInBlockWindow(
        now: Date,
        startHour: Int,
        startMinute: Int,
        endHour: Int = 23,
        endMinute: Int = 59,
        calendar: Calendar = .current
    ) -> Bool {
        let startComponents = DateComponents(
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: calendar.component(.day, from: now),
            hour: startHour,
            minute: startMinute
        )
        let endComponents = DateComponents(
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: calendar.component(.day, from: now),
            hour: endHour,
            minute: endMinute,
            second: 59
        )
        guard let start = calendar.date(from: startComponents),
              let end = calendar.date(from: endComponents) else {
            return false
        }
        return now >= start && now <= end
    }
}
