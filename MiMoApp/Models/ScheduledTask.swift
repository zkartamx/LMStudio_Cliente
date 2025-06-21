import Foundation

/// Representa una tarea programada por el usuario.
struct ScheduledTask: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    /// Fecha y hora de ejecución
    var runDate: Date
    /// Prompt o acción a ejecutar
    var prompt: String

    init(id: UUID = UUID(), name: String, runDate: Date, prompt: String) {
        self.id = id
        self.name = name
        self.runDate = runDate
        self.prompt = prompt
    }
}
