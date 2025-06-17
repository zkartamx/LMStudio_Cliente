//archivo ServerConfigViewModel
import Foundation
import SwiftUI

@MainActor
class ServerConfigViewModel: ObservableObject {
    // MARK: — Configuración del servidor
    @Published var address = UserDefaults.standard.string(forKey: "lmHost") ?? ""
    @Published var port = UserDefaults.standard.string(forKey: "lmPort") ?? ""
    @Published var supportsImageInput: Bool = false
    @Published var appVersion: String = "0.0.4"

    // MARK: — Modelos
    @Published var models = UserDefaults.standard.stringArray(forKey: "lmModels") ?? []
    @Published public var modelDetails: [String: AIModelsResponse.Model] = [:]
    
    @Published var selectedModel: String = UserDefaults.standard.string(forKey: "lmSelectedModel") ?? "" {
        didSet {
            UserDefaults.standard.set(selectedModel, forKey: "lmSelectedModel")
            updateSupportsImageInput()
        }
    }

    private let imageCapableModelsKey = "lmModelsThatSupportImage"

    private var imageCapableModels: [String] {
        get {
            if let data = UserDefaults.standard.data(forKey: imageCapableModelsKey),
               let models = try? JSONDecoder().decode([String].self, from: data) {
                return models
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: imageCapableModelsKey)
            }
        }
    }


    // MARK: — Estado
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let session = URLSession.shared

    // MARK: — URL de modelos
    private var modelsURL: URL? {
        guard !address.isEmpty, let p = Int(port) else { return nil }
        return URL(string: "http://\(address):\(p)/v1/models")
    }

    // MARK: — Cargar modelos
    func fetchModels() async {
        print("🔍 Dirección actual: \(address), Puerto actual: \(port)")
        print("✅ fetchModels() ejecutado")

        guard let url = modelsURL else {
            print("❌ modelsURL inválida — probablemente falta IP o puerto")
            errorMessage = "Dirección o puerto inválidos"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let (data, _) = try await session.data(from: url)

            // Mostrar respuesta sin procesar para depuración
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            print("🧾 Respuesta completa de modelos:\n\(json)")

            let resp = try JSONDecoder().decode(AIModelsResponse.self, from: data)

            modelDetails = Dictionary(uniqueKeysWithValues: resp.data.map { ($0.id, $0) })

            models = resp.data.map { $0.id }
            UserDefaults.standard.set(models, forKey: "lmModels")

            // Detectar y guardar modelos compatibles con imágenes
            let compatibles = resp.data.filter { model in
                if let modalities = model.modality {
                    return modalities.contains("image")
                } else {
                    let id = model.id.lowercased()
                    return id.contains("vision") || id.contains("vl") || id.contains("image")
                }
            }.map { $0.id }

            imageCapableModels = compatibles

            // Validar selección de modelo actual
            if selectedModel.isEmpty || !models.contains(selectedModel) {
                selectedModel = models.first ?? ""
            } else {
                updateSupportsImageInput()
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: — Verifica si el modelo soporta imágenes
    private func updateSupportsImageInput() {
        supportsImageInput = imageCapableModels.contains(selectedModel)
        print("🧠 Modelo seleccionado: \(selectedModel) → Soporta imágenes: \(supportsImageInput)")
    }

    // MARK: — Función auxiliar
    func modelSupportsImages(_ modelID: String) -> Bool {
        return imageCapableModels.contains(modelID)
    }

    // MARK: — Guardar configuración
    func saveConfiguration() {
        UserDefaults.standard.set(address, forKey: "lmHost")
        UserDefaults.standard.set(port, forKey: "lmPort")
        UserDefaults.standard.set(selectedModel, forKey: "lmSelectedModel")
    }

    // MARK: — Limpiar configuración
    func clearConfiguration() {
        address = ""
        port = ""
        models = []
        selectedModel = ""
        errorMessage = nil
        supportsImageInput = false
        imageCapableModels = []

        UserDefaults.standard.removeObject(forKey: "lmHost")
        UserDefaults.standard.removeObject(forKey: "lmPort")
        UserDefaults.standard.removeObject(forKey: "lmModels")
        UserDefaults.standard.removeObject(forKey: "lmSelectedModel")
        UserDefaults.standard.removeObject(forKey: "lmModelsThatSupportImage")
    }
}

