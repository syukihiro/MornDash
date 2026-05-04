import Foundation

enum StatsFormatters {
    static func duration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 {
            return String(format: NSLocalizedString("onboarding_usage_hm_format", comment: ""), hours, minutes)
        } else if hours > 0 {
            return String(format: NSLocalizedString("onboarding_usage_h_only_format", comment: ""), hours)
        } else if minutes > 0 {
            return String(format: NSLocalizedString("onboarding_usage_m_only_format", comment: ""), minutes)
        } else {
            return NSLocalizedString("onboarding_usage_under_one_m", comment: "")
        }
    }

    static func percentChange(current: TimeInterval, previous: TimeInterval) -> Double? {
        guard previous > 0 else { return nil }
        return (current - previous) / previous
    }

    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    static func weekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEEEE")
        return formatter.string(from: date)
    }

    static func shortMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: date)
    }

    static func yearRange(from start: Date, to end: Date) -> String {
        let cal = Calendar.current
        let startYear = cal.component(.year, from: start)
        let endYear = cal.component(.year, from: end)
        return startYear == endYear ? "\(endYear)" : "\(startYear) – \(endYear)"
    }
}
