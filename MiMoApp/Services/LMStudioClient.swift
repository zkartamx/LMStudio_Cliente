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
        systemPrompt: String,
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

        var messages: [[String: String]] = []
        if !systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append(["role": "system", "content": systemPrompt])
        }
        messages.append(["role": "user", "content": prompt])

        let body: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": messages
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
}

