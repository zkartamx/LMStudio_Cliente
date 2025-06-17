import Foundation

/// Representa la respuesta del endpoint `/v1/models` de LM Studio.
struct AIModelsResponse: Codable {
    struct Model: Codable {
        let id: String
        let modality: [String]?

        var supportsImages: Bool {
            // 👇 Detección manual basada en IDs conocidos
            Self.imageCapableModels.contains(id)
        }

        // Agrega aquí los IDs conocidos que aceptan imágenes
        private static let imageCapableModels: Set<String> = [
            "mimo-vl-7b-rl@q4_k_s",
            "mimo-vl-7b-rl@iq1_m"
        ]
    }

    let data: [Model]
}

