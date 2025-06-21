import Foundation
import SwiftUI

@MainActor
class ScheduledTasksViewModel: ObservableObject {
    @Published var tasks: [ScheduledTask] = []
    var hasPendingImageTask: Bool {
        tasks.contains { $0.executedAt == nil && !$0.imageDatas.isEmpty }
    }

    private var timer: Timer?
    private weak var configVM: ServerConfigViewModel?

    private let tasksKey = "scheduledTasks"

    init() {
        load()
    }

    deinit {
        timer?.invalidate()
    }

    func addTask(name: String, date: Date, prompt: String, images: [Data] = []) {
        let task = ScheduledTask(name: name, runDate: date, prompt: prompt, imageDatas: images)
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

        for index in tasks.indices {
            var task = tasks[index]
            guard task.executedAt == nil, task.runDate <= now else { continue }

            var response: String? = nil
            if !task.imageDatas.isEmpty {
                response = await LMStudioClient.sendPromptWithImagesOnce(
                    to: config.selectedModel,
                    prompt: task.prompt,
                    imageDatas: task.imageDatas,
                    host: config.address,
                    port: config.port
                )
            } else if !task.prompt.isEmpty {
                response = await LMStudioClient.sendPromptOnce(
                    to: config.selectedModel,
                    prompt: task.prompt,
                    host: config.address,
                    port: config.port
                )
            }

            task.executedAt = Date()
            task.responseLog = response
            tasks[index] = task
        }

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
