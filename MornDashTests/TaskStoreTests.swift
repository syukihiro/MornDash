import XCTest
@testable import MornDash

final class TaskStoreTests: XCTestCase {
    func testAllCompletedTodayRequiresNonEmptyList() {
        var store = TaskStore()
        XCTAssertFalse(store.allCompletedToday)
    }

    func testAllCompletedTodayWhenEveryTaskDone() {
        var store = TaskStore(tasks: [
            TaskItem(title: "A", lastCompletedDate: Date()),
            TaskItem(title: "B", lastCompletedDate: Date()),
        ])
        XCTAssertTrue(store.allCompletedToday)
    }

    func testRemovePreservesMinimumOneTask() {
        var store = TaskStore(tasks: [TaskItem(title: "Only")])
        let removed = store.remove(at: IndexSet(integer: 0))
        XCTAssertFalse(removed)
        XCTAssertEqual(store.tasks.count, 1)
    }

    func testRemoveAllowsWhenMultipleTasks() {
        var store = TaskStore(tasks: [
            TaskItem(title: "A"),
            TaskItem(title: "B"),
        ])
        let removed = store.remove(at: IndexSet(integer: 0))
        XCTAssertTrue(removed)
        XCTAssertEqual(store.tasks.count, 1)
    }
}
