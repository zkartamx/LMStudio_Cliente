import Foundation
import SwiftUI

@MainActor
class ScheduledTasksViewModel: ObservableObject {
    @Published var tasks: [ScheduledTask] = []

    private let tasksKey = "scheduledTasks"

    init() {
        load()
    }

    func addTask(name: String, schedule: String, prompt: String) {
        let task = ScheduledTask(name: name, schedule: schedule, prompt: prompt)
        tasks.append(task)
        save()
    }

    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Persistence
    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: tasksKey),
            let saved = try? JSONDecoder().decode([ScheduledTask].self, from: data)
        else { return }
        tasks = saved
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }
    }
}
