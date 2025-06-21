import Foundation
import SwiftUI

@MainActor
class ScheduledTasksViewModel: ObservableObject {
    @Published var tasks: [ScheduledTask] = []

    private var timer: Timer?
    private weak var configVM: ServerConfigViewModel?

    private let tasksKey = "scheduledTasks"

    init() {
        load()
    }

    deinit {
        timer?.invalidate()
    }

    func addTask(name: String, date: Date, prompt: String) {
        let task = ScheduledTask(name: name, runDate: date, prompt: prompt)
        tasks.append(task)
        save()
    }

    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Monitoring
    func startMonitoring(config: ServerConfigViewModel) {
        configVM = config
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { await self?.checkDueTasks() }
        }
    }

    private func checkDueTasks() async {
        guard let config = configVM else { return }
        let now = Date()
        let due = tasks.filter { $0.runDate <= now }
        guard !due.isEmpty else { return }

        for task in due {
            if !task.prompt.isEmpty {
                _ = await LMStudioClient.sendPromptOnce(
                    to: config.selectedModel,
                    prompt: task.prompt,
                    host: config.address,
                    port: config.port
                )
            }
        }

        tasks.removeAll { $0.runDate <= now }
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
