//
//  ConversationsViewModel.swift
//  MiMoApp
//
//  Created by Carlos Daniel Arteaga Hernandez on 13/06/25.
//

// MARK: - ConversationsViewModel.swift
import Foundation
import SwiftUI

struct Conversation: Identifiable, Equatable {
    let id: UUID
    var name: String
    var systemPrompt: String
    var messages: [ChatMessage]

    init(name: String, systemPrompt: String = "", messages: [ChatMessage] = []) {
        self.id = UUID()
        self.name = name
        self.systemPrompt = systemPrompt
        self.messages = messages
    }

    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.systemPrompt == rhs.systemPrompt &&
        lhs.messages == rhs.messages
    }
}


@MainActor
class ConversationsViewModel: ObservableObject {
    @Published var conversations: [Conversation] = [Conversation(name: "Tab 1")]
    @Published var currentConversationIndex: Int = 0

    var currentConversation: Conversation {
        get { conversations[currentConversationIndex] }
        set { conversations[currentConversationIndex] = newValue }
    }

    func addNewConversation() {
        let newName = "Tab \(conversations.count + 1)"
        conversations.append(Conversation(name: newName))
        currentConversationIndex = conversations.count - 1
    }
    
    func deleteConversation(at index: Int) {
        guard conversations.indices.contains(index) else { return }
        conversations.remove(at: index)
        if conversations.isEmpty {
            addNewConversation()
        } else {
            currentConversationIndex = max(0, min(currentConversationIndex, conversations.count - 1))
        }
    }

}
