import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var isStreaming: Bool = false
    @Published var showingImagePicker: Bool = false
    @Published var selectedImages: [UIImage] = []

    var bindingMessages: Binding<[ChatMessage]>
    private(set) var streamedResponse: String = ""
    private var streamingTask: Task<Void, Never>?
    private var lastBotMessageIndex: Int?

    init(bindingMessages: Binding<[ChatMessage]>) {
        self.bindingMessages = bindingMessages
    }

   
    func sendPrompt(model: String, host: String, port: String, systemPrompt: String) {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        // 1) Capturamos en variables locales
        let promptText = input
        let promptImages = selectedImages

        // 2) Limpiamos YA el input y las imágenes en la UI
        userInput = ""
        selectedImages = []

        // 3) Preparamos el mensaje de usuario y el bot vacío
        isStreaming = true
        streamedResponse = ""

        let userMessage = ChatMessage(text: promptText, images: promptImages, isUser: true)
        bindingMessages.wrappedValue.append(userMessage)

        let emptyBotMessage = ChatMessage(text: "", isUser: false)
        bindingMessages.wrappedValue.append(emptyBotMessage)
        lastBotMessageIndex = bindingMessages.wrappedValue.count - 1

        // 4) Disparamos la petición
        if promptImages.isEmpty {
            // Texto sólo (streaming)
            streamingTask = LMStudioClient.sendMessageStreaming(
                to: model,
                prompt: promptText,
                host: host,
                port: port,
                systemPrompt: systemPrompt,
                onUpdate: { [weak self] partial in
                    Task { @MainActor in
                        guard let self = self, let idx = self.lastBotMessageIndex else { return }
                        self.streamedResponse = partial
                        self.bindingMessages.wrappedValue[idx].text = partial
                    }
                },
                onFinish: { [weak self] in
                    Task { @MainActor in
                        guard let self = self else { return }
                        self.isStreaming = false
                        self.streamingTask = nil
                        self.lastBotMessageIndex = nil
                    }
                }
            )
        } else {
            // Texto + imágenes (petición no‐streaming)
            sendMultipleImagesWithPromptToModel(
                images: promptImages,
                prompt: promptText,
                model: model,
                host: host,
                port: port,
                systemPrompt: systemPrompt
            ) { [weak self] response in
                Task { @MainActor in
                    guard let self = self, let idx = self.lastBotMessageIndex else { return }
                    self.bindingMessages.wrappedValue[idx].text = response ?? "⚠️ Respuesta inválida"
                    self.isStreaming = false
                    self.streamingTask = nil
                    self.lastBotMessageIndex = nil
                }
            }
        }
    }


    func stopStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
    }

    func sendMultipleImagesWithPromptToModel(
        images: [UIImage],
        prompt: String,
        model: String,
        host: String,
        port: String,
        systemPrompt: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let url = URL(string: "http://\(host):\(port)/v1/chat/completions") else {
            completion("URL inválida.")
            return
        }

        let imageContents: [[String: Any]] = images.compactMap {
            guard let imageData = $0.jpegData(compressionQuality: 0.8) else { return nil }
            let base64 = imageData.base64EncodedString()
            return [
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
            ]
        }

        var messages: [[String: Any]] = []
        if !systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append(["role": "system", "content": systemPrompt])
        }
        messages.append([
            "role": "user",
            "content": imageContents + [["type": "text", "text": prompt]]
        ])

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": -1,
            "stream": false
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion("Error codificando JSON: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion("Error de red: \(error?.localizedDescription ?? "Desconocido")")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data),
               let dict = json as? [String: Any],
               let choices = dict["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content)
            } else {
                completion("Respuesta no válida del modelo.")
            }
        }.resume()
    }
}

