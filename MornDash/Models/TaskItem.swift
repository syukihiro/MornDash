import Foundation
import SwiftUI

enum WorkoutKind: String, Codable, Equatable {
    case squat
}

enum FocusDetectionKind: String, Codable, Equatable {
    case study, pcWork
}

struct TaskItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var lastCompletedDate: Date?
    var workout: WorkoutKind?
    var targetReps: Int?
    var timerDurationSeconds: Int?
    var focusKind: FocusDetectionKind?
    var focusTargetSeconds: Int?
    var focusAccumulatedSeconds: Int?
    var focusSessionStartedAt: Date?

    var isCompletedToday: Bool {
        guard let date = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    var isWorkoutTask: Bool {
        workout != nil
    }

    var hasTimer: Bool {
        guard let timerDurationSeconds else { return false }
        return timerDurationSeconds > 0
    }

    var isFocusTask: Bool {
        focusKind != nil
    }
}

struct TaskStore: Codable {
    var tasks: [TaskItem] = []

    var allCompletedToday: Bool {
        !tasks.isEmpty && tasks.allSatisfy { $0.isCompletedToday }
    }

    var completedCount: Int {
        tasks.filter(\.isCompletedToday).count
    }

    var timerTaskCount: Int {
        tasks.filter(\.hasTimer).count
    }

    mutating func toggle(_ id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        if tasks[idx].isCompletedToday {
            tasks[idx].lastCompletedDate = nil
        } else {
            tasks[idx].lastCompletedDate = Date()
        }
    }

    mutating func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(TaskItem(title: trimmed))
    }

    mutating func addWorkout(_ workout: WorkoutKind, targetReps: Int, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, targetReps > 0 else { return }
        tasks.append(TaskItem(title: trimmed, workout: workout, targetReps: targetReps))
    }

    mutating func addFocus(kind: FocusDetectionKind, targetSeconds: Int, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, targetSeconds > 0 else { return }
        tasks.append(TaskItem(title: trimmed, focusKind: kind, focusTargetSeconds: targetSeconds, focusAccumulatedSeconds: 0))
    }

    mutating func updateFocusAccumulated(_ id: UUID, accumulated: Int, sessionStart: Date?) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].focusAccumulatedSeconds = accumulated
        tasks[idx].focusSessionStartedAt = sessionStart
    }

    mutating func clearFocusSession(_ id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].focusSessionStartedAt = nil
    }

    mutating func remove(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }

    mutating func update(_ id: UUID, title: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].title = title
    }

    mutating func updateTimer(_ id: UUID, timerDurationSeconds: Int?) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].timerDurationSeconds = timerDurationSeconds
    }

    private static let saveKey = "mornDash_task_store"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    static func load() -> TaskStore {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(TaskStore.self, from: data) {
            var migrated = decoded
            let meditateTitle = NSLocalizedString("onboarding_preset_meditate", comment: "")
            for index in migrated.tasks.indices where migrated.tasks[index].title == meditateTitle {
                if migrated.tasks[index].timerDurationSeconds == nil {
                    migrated.tasks[index].timerDurationSeconds = 5 * 60
                }
            }
            let now = Date()
            let staleSessionThreshold: TimeInterval = 4 * 60 * 60
            for index in migrated.tasks.indices {
                guard migrated.tasks[index].isFocusTask else { continue }
                if !migrated.tasks[index].isCompletedToday {
                    migrated.tasks[index].focusAccumulatedSeconds = 0
                    migrated.tasks[index].focusSessionStartedAt = nil
                } else if let startedAt = migrated.tasks[index].focusSessionStartedAt,
                          now.timeIntervalSince(startedAt) > staleSessionThreshold {
                    migrated.tasks[index].focusSessionStartedAt = nil
                }
            }
            return migrated
        }
        return TaskStore(tasks: [
            TaskItem(title: NSLocalizedString("default_task_stretch", comment: "")),
            TaskItem(title: NSLocalizedString("default_task_water", comment: "")),
            TaskItem(title: NSLocalizedString("default_task_face", comment: ""))
        ])
    }
}
