import Foundation

/// Representa una tarea programada por el usuario.
struct ScheduledTask: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    /// Expresión cron o descripción de la programación
    var schedule: String
    /// Prompt o acción a ejecutar
    var prompt: String

    init(id: UUID = UUID(), name: String, schedule: String, prompt: String) {
        self.id = id
        self.name = name
        self.schedule = schedule
        self.prompt = prompt
    }
}
