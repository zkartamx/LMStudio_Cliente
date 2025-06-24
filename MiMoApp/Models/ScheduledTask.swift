import Foundation

/// Representa una tarea programada por el usuario.
struct ScheduledTask: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    /// Fecha y hora de ejecución
    var runDate: Date
    /// Prompt o acción a ejecutar
    var prompt: String
    /// Imágenes adjuntas codificadas en JPEG
    var imageDatas: [Data] = []
    /// Fecha de ejecución real (nulo si aún no se ejecuta)
    var executedAt: Date? = nil
    /// Registro de la respuesta obtenida
    var responseLog: String? = nil

    init(id: UUID = UUID(), name: String, runDate: Date, prompt: String,
         imageDatas: [Data] = [], executedAt: Date? = nil, responseLog: String? = nil) {
        self.id = id
        self.name = name
        self.runDate = runDate
        self.prompt = prompt
        self.imageDatas = imageDatas
        self.executedAt = executedAt
        self.responseLog = responseLog
    }
}
