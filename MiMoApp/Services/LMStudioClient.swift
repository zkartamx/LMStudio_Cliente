// MARK: - LMStudioClient.swift
import Foundation

struct StreamDelta: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}

class LMStudioClient {
    static func sendMessageStreaming(
        to model: String,
        prompt: String,
        host: String,
        port: String,
        onUpdate: @escaping (String) -> Void,
        onFinish: @escaping () -> Void
    ) -> Task<Void, Never> {
        guard let url = URL(string: "http://\(host):\(port)/v1/chat/completions") else {
            onFinish()
            return Task { }
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            onFinish()
            return Task { }
        }

        let task = Task {
            var response = ""

            do {
                let (stream, _) = try await URLSession.shared.bytes(for: request)
                for try await line in stream.lines {
                    if line.hasPrefix("data: ") {
                        let jsonPart = String(line.dropFirst(6))
                        if jsonPart == "[DONE]" {
                            onFinish()
                            break
                        }

                        if let data = jsonPart.data(using: .utf8),
                           let delta = try? JSONDecoder().decode(StreamDelta.self, from: data),
                           let content = delta.choices.first?.delta.content {
                            response += content
                            onUpdate(response)
                        }
                    }
                }
            } catch {
                onFinish()
            }
        }

        return task
    }

    /// Envía un prompt de texto y devuelve la respuesta completa de forma síncrona.
    static func sendPromptOnce(
        to model: String,
        prompt: String,
        host: String,
        port: String
    ) async -> String? {
        guard let url = URL(string: "http://\(host):\(port)/v1/chat/completions") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            }
        } catch {
            return nil
        }

        return nil
    }

    /// Envía un prompt con imágenes y devuelve la respuesta completa.
    static func sendPromptWithImagesOnce(
        to model: String,
        prompt: String,
        imageDatas: [Data],
        host: String,
        port: String
    ) async -> String? {
        guard let url = URL(string: "http://\(host):\(port)/v1/chat/completions") else {
            return nil
        }

        let imageContents: [[String: Any]] = imageDatas.map { data in
            let base64 = data.base64EncodedString()
            return [
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
            ]
        }

        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": imageContents + [["type": "text", "text": prompt]]
                ]
            ],
            "temperature": 0.7,
            "max_tokens": -1,
            "stream": false
        ] as [String : Any]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content
            }
        } catch {
            return nil
        }

        return nil
    }
}

