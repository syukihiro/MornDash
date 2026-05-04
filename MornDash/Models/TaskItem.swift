import Foundation
import SwiftUI

struct TaskItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var lastCompletedDate: Date?

    var isCompletedToday: Bool {
        guard let date = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(date)
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

    mutating func remove(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }

    mutating func update(_ id: UUID, title: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].title = title
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
            return decoded
        }
        return TaskStore(tasks: [
            TaskItem(title: NSLocalizedString("default_task_stretch", comment: "")),
            TaskItem(title: NSLocalizedString("default_task_water", comment: "")),
            TaskItem(title: NSLocalizedString("default_task_face", comment: ""))
        ])
    }
}
