import Foundation
import SwiftUI

enum WorkoutKind: String, Codable, Equatable {
    case squat
}

struct TaskItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var lastCompletedDate: Date?
    var workout: WorkoutKind?
    var targetReps: Int?
    var timerDurationSeconds: Int?

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
            return migrated
        }
        return TaskStore(tasks: [
            TaskItem(title: NSLocalizedString("default_task_stretch", comment: "")),
            TaskItem(title: NSLocalizedString("default_task_water", comment: "")),
            TaskItem(title: NSLocalizedString("default_task_face", comment: ""))
        ])
    }
}
